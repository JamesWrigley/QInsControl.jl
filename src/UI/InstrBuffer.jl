mutable struct InstrQuantity
    # back end
    enable::Bool
    name::String
    alias::String
    step::String
    stop::String
    delay::Cfloat
    set::String
    optkeys::Vector{String}
    optvalues::Vector{String}
    optedidx::Cint
    read::String
    utype::String
    uindex::Int
    type::Symbol
    help::String
    isautorefresh::Bool
    issweeping::Bool
    # front end
    show_edit::String
    show_view::String
    passfilter::Bool
end
InstrQuantity() = InstrQuantity(
    true, "", "", "", "", Cfloat(0.1), "", [], [], 1, "", "", 1, :set, "", false, false,
    "", "", true
)
InstrQuantity(name, qtcf::QuantityConf) = InstrQuantity(
    qtcf.enable, name, qtcf.alias,
    "", "", Cfloat(0.1),
    "", qtcf.optkeys, qtcf.optvalues, 1,
    "",
    qtcf.U, 1,
    Symbol(qtcf.type),
    qtcf.help,
    false,
    false,
    "", "", true
)

function getvalU(qt::InstrQuantity)
    Us = CONF.U[qt.utype]
    U = isempty(Us) ? "" : Us[qt.uindex]
    U == "" || (Uchange::Float64 = Us[1] isa Unitful.FreeUnits ? ustrip(Us[1], 1U) : 1.0)
    val = U == "" ? qt.read : @trypass string(parse(Float64, qt.read) / Uchange) qt.read
    return val, U
end

function updatefront!(qt::InstrQuantity, ::Val{:sweep})
    val, U = getvalU(qt)
    content = string(
        qt.alias,
        "\n", mlstr("step"), ": ", qt.step, " ", U,
        "\n", mlstr("stop"), ": ", qt.stop, " ", U,
        "\n", mlstr("delay"), ": ", qt.delay, " s\n",
        val, " ", U
    ) |> centermultiline
    qt.show_edit = string(content, "###for refresh")
end

function updatefront!(qt::InstrQuantity, ::Val{:set})
    val, U = getvalU(qt)
    if val in qt.optvalues
        validx = findfirst(==(val), qt.optvalues)
        val = string(qt.optkeys[validx], " => ", qt.optvalues[validx])
    end
    content = string(
        qt.alias,
        "\n \n",
        mlstr("set value"), ": ", qt.set, " ", U,
        "\n \n",
        val, " ", U
    ) |> centermultiline
    qt.show_edit = string(content, "###for refresh")
end

function updatefront!(qt::InstrQuantity, ::Val{:read})
    val, U = getvalU(qt)
    content = string(qt.alias, "\n \n \n", val, " ", U, "\n ") |> centermultiline
    qt.show_edit = string(content, "###for refresh")
end

function updatefront!(qt::InstrQuantity; show_edit=true)
    if show_edit
        updatefront!(qt, Val(qt.type))
    else
        val, U = getvalU(qt)
        if qt.type == :set && val in qt.optvalues
            validx = findfirst(==(val), qt.optvalues)
            val = string(qt.optkeys[validx], " => ", qt.optvalues[validx])
        end
        qt.show_view = string(qt.alias, "\n", val, " ", U) |> centermultiline
    end
end

mutable struct InstrBuffer
    instrnm::String
    quantities::OrderedDict{String,InstrQuantity}
    isautorefresh::Bool
    filter::String
    filtervarname::Bool
end
InstrBuffer() = InstrBuffer("", OrderedDict(), false, "", false)

function InstrBuffer(instrnm)
    haskey(insconf, instrnm) || @error "[$(now())]\n$(mlstr("unsupported instrument!!!"))" instrument = instrnm
    sweepqts = [qt for qt in keys(insconf[instrnm].quantities) if insconf[instrnm].quantities[qt].type == "sweep"]
    setqts = [qt for qt in keys(insconf[instrnm].quantities) if insconf[instrnm].quantities[qt].type == "set"]
    readqts = [qt for qt in keys(insconf[instrnm].quantities) if insconf[instrnm].quantities[qt].type == "read"]
    quantities = [sweepqts; setqts; readqts]
    instrqts = OrderedDict()
    for qt in quantities
        enable = insconf[instrnm].quantities[qt].enable
        alias = insconf[instrnm].quantities[qt].alias
        optkeys = insconf[instrnm].quantities[qt].optkeys
        optvalues = insconf[instrnm].quantities[qt].optvalues
        utype = insconf[instrnm].quantities[qt].U
        type = Symbol(insconf[instrnm].quantities[qt].type)
        help = replace(insconf[instrnm].quantities[qt].help, "\\\n" => "")
        push!(
            instrqts,
            qt => InstrQuantity(
                enable, qt, alias,
                "", "", Cfloat(0.1),
                "", optkeys, optvalues, 1,
                "",
                utype, 1,
                type,
                help,
                false,
                false,
                "", "", true
            )
        )
        updatefront!(instrqts[qt])
    end
    InstrBuffer(instrnm, instrqts, false, "", false)
end

function update_passfilter!(insbuf::InstrBuffer)
    for (qtnm, qt) in insbuf.quantities
        if insbuf.filter != "" && isvalid(insbuf.filter)
            qt.passfilter = if insbuf.filtervarname
                occursin(lowercase(insbuf.filter), lowercase(qtnm))
            else
                occursin(lowercase(insbuf.filter), lowercase(qt.alias))
            end
        else
            qt.passfilter = true
        end
    end
end

mutable struct InstrBufferViewer
    instrnm::String
    addr::String
    inputcmd::String
    readstr::String
    p_open::Bool
    insbuf::InstrBuffer
end
InstrBufferViewer(instrnm, addr) = InstrBufferViewer(instrnm, addr, "*IDN?", "", false, InstrBuffer(instrnm))
InstrBufferViewer() = InstrBufferViewer("", "", "*IDN?", "", false, InstrBuffer())

const INSTRBUFFERVIEWERS::Dict{String,Dict{String,InstrBufferViewer}} = Dict()

function edit(ibv::InstrBufferViewer)
    CImGui.SetNextWindowSize((800, 600), CImGui.ImGuiCond_Once)
    ins, addr = ibv.instrnm, ibv.addr
    if @c CImGui.Begin(stcstr(insconf[ins].conf.icon, "  ", ins, " --- ", addr), &ibv.p_open)
        @c testcmd(ins, addr, &ibv.inputcmd, &ibv.readstr)
        edit(ibv.insbuf, addr)
        if !CImGui.IsAnyItemHovered() && CImGui.IsWindowHovered(CImGui.ImGuiHoveredFlags_ChildWindows)
            CImGui.OpenPopupOnItemClick("rightclick")
        end
        if CImGui.BeginPopup("rightclick")
            if CImGui.MenuItem(stcstr(MORESTYLE.Icons.InstrumentsManualRef, " ", mlstr("manual refresh")), "F5")
                ibv.insbuf.isautorefresh = true
                manualrefresh()
                for ins in keys(INSTRBUFFERVIEWERS)
                    for (_, ibv) in INSTRBUFFERVIEWERS[ins]
                        for (_, qt) in ibv.insbuf.quantities
                            updatefront!(qt)
                        end
                    end
                end
            end
            CImGui.Text(stcstr(MORESTYLE.Icons.InstrumentsAutoRef, " ", mlstr("auto refresh")))
            CImGui.SameLine()
            isautoref = SYNCSTATES[Int(IsAutoRefreshing)]
            @c CImGui.Checkbox("##auto refresh", &isautoref)
            SYNCSTATES[Int(IsAutoRefreshing)] = isautoref
            ibv.insbuf.isautorefresh = SYNCSTATES[Int(IsAutoRefreshing)]
            if isautoref
                CImGui.SameLine()
                CImGui.Text(" ")
                CImGui.SameLine()
                CImGui.PushItemWidth(CImGui.GetFontSize() * 2)
                @c CImGui.DragFloat(
                    "##auto refresh",
                    &CONF.InsBuf.refreshrate,
                    0.1, 0.1, 60, "%.1f",
                    CImGui.ImGuiSliderFlags_AlwaysClamp
                )
                CImGui.PopItemWidth()
            end
            CImGui.Text(stcstr(MORESTYLE.Icons.ShowCol, " ", mlstr("display columns")))
            CImGui.SameLine()
            CImGui.PushItemWidth(3CImGui.GetFontSize() / 2)
            @c CImGui.DragInt(
                "##display columns",
                &CONF.InsBuf.showcol, 1, 1, 12, "%d",
                CImGui.ImGuiSliderFlags_AlwaysClamp
            )
            CImGui.PopItemWidth()
            CImGui.EndPopup()
        end
        CImGui.IsKeyReleased(294) && manualrefresh()
    end
    CImGui.End()
end

let
    firsttime::Bool = true
    selectedins::String = ""
    selectedaddr::String = ""
    inputcmd::String = "*IDN?"
    readstr::String = ""
    default_insbufs = Dict{String,InstrBuffer}()
    global function ShowInstrBuffer(p_open::Ref)
        CImGui.SetNextWindowSize((800, 600), CImGui.ImGuiCond_Once)
        if CImGui.Begin(
            stcstr(MORESTYLE.Icons.InstrumentsOverview, "  ", mlstr("Instrument Settings and Status"), "###insbuf"),
            p_open
        )
            CImGui.Columns(2)
            firsttime && (CImGui.SetColumnOffset(1, CImGui.GetWindowWidth() * 0.25); firsttime = false)
            CImGui.BeginChild("instrument list")
            CImGui.Selectable(
                stcstr(MORESTYLE.Icons.InstrumentsOverview, " ", mlstr("Overview")),
                selectedins == ""
            ) && (selectedins = "")
            for ins in keys(INSTRBUFFERVIEWERS)
                CImGui.Selectable(stcstr(insconf[ins].conf.icon, " ", ins), selectedins == ins) && (selectedins = ins)
                CImGui.SameLine()
                CImGui.TextDisabled(stcstr("(", length(INSTRBUFFERVIEWERS[ins]), ")"))
            end
            CImGui.EndChild()
            if CImGui.BeginPopupContextItem()
                if CImGui.MenuItem(stcstr(MORESTYLE.Icons.InstrumentsManualRef, " ", mlstr("manual refresh")), "F5")
                    manualrefresh()
                    for ins in keys(INSTRBUFFERVIEWERS)
                        for (_, ibv) in INSTRBUFFERVIEWERS[ins]
                            for (_, qt) in ibv.insbuf.quantities
                                updatefront!(qt)
                            end
                        end
                    end
                end
                CImGui.Text(stcstr(MORESTYLE.Icons.InstrumentsAutoRef, " ", mlstr("auto refresh")))
                CImGui.SameLine()
                isautoref = SYNCSTATES[Int(IsAutoRefreshing)]
                @c CImGui.Checkbox("##auto refresh", &isautoref)
                SYNCSTATES[Int(IsAutoRefreshing)] = isautoref
                if isautoref
                    CImGui.SameLine()
                    CImGui.Text(" ")
                    CImGui.SameLine()
                    CImGui.PushItemWidth(CImGui.GetFontSize() * 2)
                    @c CImGui.DragFloat(
                        "##auto refresh",
                        &CONF.InsBuf.refreshrate,
                        0.1, 0.1, 60, "%.1f",
                        CImGui.ImGuiSliderFlags_AlwaysClamp
                    )
                    CImGui.PopItemWidth()
                end
                CImGui.Text(stcstr(MORESTYLE.Icons.ShowCol, " ", mlstr("display columns")))
                CImGui.SameLine()
                CImGui.PushItemWidth(3CImGui.GetFontSize() / 2)
                @c CImGui.DragInt(
                    "##display columns",
                    &CONF.InsBuf.showcol,
                    1, 1, 12, "%d",
                    CImGui.ImGuiSliderFlags_AlwaysClamp
                )
                CImGui.PopItemWidth()
                CImGui.EndPopup()
            end
            CImGui.IsKeyReleased(294) && manualrefresh()
            CImGui.NextColumn()
            CImGui.BeginChild("setings")
            haskey(INSTRBUFFERVIEWERS, selectedins) || (selectedins = "")
            if selectedins == ""
                for ins in keys(INSTRBUFFERVIEWERS)
                    CImGui.TextColored(MORESTYLE.Colors.HighlightText, stcstr(ins, ": "))
                    for (addr, ibv) in INSTRBUFFERVIEWERS[ins]
                        CImGui.Text(stcstr("\t\t", addr, "\t\t"))
                        CImGui.SameLine()
                        @c CImGui.Checkbox(stcstr("##if auto refresh", addr), &ibv.insbuf.isautorefresh)
                        if ins != "VirtualInstr"
                            CImGui.SameLine()
                            CImGui.Button(
                                stcstr(MORESTYLE.Icons.CloseFile, "##delete ", addr)
                            ) && delete!(INSTRBUFFERVIEWERS[ins], addr)
                        end
                    end
                    CImGui.Separator()
                end
            else
                showinslist::Set = @trypass keys(INSTRBUFFERVIEWERS[selectedins]) Set{String}()
                CImGui.PushItemWidth(-CImGui.GetFontSize() * 2.5)
                @c ComBoS(mlstr("address"), &selectedaddr, showinslist)
                CImGui.PopItemWidth()
                CImGui.Separator()
                @c testcmd(selectedins, selectedaddr, &inputcmd, &readstr)

                selectedaddr = haskey(INSTRBUFFERVIEWERS[selectedins], selectedaddr) ? selectedaddr : ""
                haskey(default_insbufs, selectedins) || push!(default_insbufs, selectedins => InstrBuffer(selectedins))
                insbuf = selectedaddr == "" ? default_insbufs[selectedins] : INSTRBUFFERVIEWERS[selectedins][selectedaddr].insbuf
                edit(insbuf, selectedaddr)
            end
            CImGui.EndChild()
        end
        CImGui.End()
    end
end #let    

function testcmd(ins, addr, inputcmd::Ref{String}, readstr::Ref{String})
    if CImGui.CollapsingHeader(stcstr("\t", mlstr("Command Test")))
        y = (1 + length(findall("\n", inputcmd[]))) * CImGui.GetTextLineHeight() +
            2unsafe_load(IMGUISTYLE.FramePadding.y)
        InputTextMultilineRSZ("##input cmd", inputcmd, (Float32(-1), y))
        if CImGui.BeginPopupContextItem()
            CImGui.MenuItem(mlstr("clear")) && (inputcmd[] = "")
            CImGui.EndPopup()
        end
        TextRect(stcstr(readstr[], "\n "))
        CImGui.BeginChild("align buttons", (Float32(0), CImGui.GetFrameHeightWithSpacing()))
        CImGui.PushStyleVar(CImGui.ImGuiStyleVar_FrameRounding, 12)
        CImGui.Columns(3, C_NULL, false)
        if CImGui.Button(stcstr(MORESTYLE.Icons.WriteBlock, "  ", mlstr("Write")), (-1, 0))
            if addr != ""
                remotecall_wait(workers()[1], ins, addr, inputcmd[]) do ins, addr, inputcmd
                    ct = Controller(ins, addr)
                    try
                        login!(CPU, ct)
                        ct(write, CPU, inputcmd, Val(:write))
                        logout!(CPU, ct)
                    catch e
                        @error(
                            "[$(now())]\n$(mlstr("instrument communication failed!!!"))",
                            instrument = string(ins, ": ", addr),
                            exception = e
                        )
                        logout!(CPU, ct)
                    end
                end
            end
        end
        CImGui.NextColumn()
        if CImGui.Button(stcstr(MORESTYLE.Icons.QueryBlock, "  ", mlstr("Query")), (-1, 0))
            if addr != ""
                fetchdata = remotecall_fetch(workers()[1], ins, addr, inputcmd[]) do ins, addr, inputcmd
                    ct = Controller(ins, addr)
                    try
                        login!(CPU, ct)
                        readstr = ct(query, CPU, inputcmd, Val(:query))
                        logout!(CPU, ct)
                        return readstr
                    catch e
                        @error(
                            "[$(now())]\n$(mlstr("instrument communication failed!!!"))",
                            instrument = string(ins, ": ", addr),
                            exception = e
                        )
                        logout!(CPU, ct)
                    end
                end
                isnothing(fetchdata) || (readstr[] = fetchdata)
            end
        end
        CImGui.NextColumn()
        if CImGui.Button(stcstr(MORESTYLE.Icons.ReadBlock, "  ", mlstr("Read")), (-1, 0))
            if addr != ""
                fetchdata = remotecall_fetch(workers()[1], ins, addr) do ins, addr
                    ct = Controller(ins, addr)
                    try
                        login!(CPU, ct)
                        readstr = ct(read, CPU, Val(:read))
                        logout!(CPU, ct)
                        return readstr
                    catch e
                        @error(
                            "[$(now())]\n$(mlstr("instrument communication failed!!!"))",
                            instrument = string(ins, ": ", addr),
                            exception = e
                        )
                        logout!(CPU, ct)
                    end
                end
                isnothing(fetchdata) || (readstr[] = fetchdata)
            end
        end
        CImGui.NextColumn()
        CImGui.PopStyleVar()
        CImGui.EndChild()
        CImGui.Separator()
    end
end


function edit(insbuf::InstrBuffer, addr)
    CImGui.PushID(insbuf.instrnm)
    CImGui.PushID(addr)
    @c(InputTextRSZ("##filterqt", &insbuf.filter)) && update_passfilter!(insbuf)
    CImGui.SameLine()
    @c(CImGui.Checkbox(
        insbuf.filtervarname ? mlstr("Filter variables") : mlstr("Filter aliases"),
        &insbuf.filtervarname
    )) && update_passfilter!(insbuf)
    CImGui.BeginChild("InstrBuffer")
    CImGui.Columns(CONF.InsBuf.showcol, C_NULL, false)
    for (i, qt) in enumerate(values(insbuf.quantities))
        qt.enable || continue
        qt.passfilter || continue
        CImGui.PushID(qt.name)
        edit(qt, insbuf.instrnm, addr)
        CImGui.PopID()
        CImGui.NextColumn()
        CImGui.Indent()
        if CImGui.BeginDragDropSource(0)
            @c CImGui.SetDragDropPayload("Swap DAQTask", &i, sizeof(Cint))
            CImGui.Text(qt.alias)
            CImGui.EndDragDropSource()
        end
        if CImGui.BeginDragDropTarget()
            payload = CImGui.AcceptDragDropPayload("Swap DAQTask")
            if payload != C_NULL && unsafe_load(payload).DataSize == sizeof(Cint)
                payload_i = unsafe_load(Ptr{Cint}(unsafe_load(payload).Data))
                if i != payload_i
                    key_i = idxkey(insbuf.quantities, i)
                    key_payload_i = idxkey(insbuf.quantities, payload_i)
                    swapvalue!(insbuf.quantities, key_i, key_payload_i)
                end
            end
            CImGui.EndDragDropTarget()
        end
        CImGui.Unindent()
    end
    CImGui.EndChild()
    CImGui.PopID()
    CImGui.PopID()
end

edit(qt::InstrQuantity, instrnm::String, addr::String) = edit(qt, instrnm, addr, Val(qt.type))

let
    stbtsz::Float32 = 0
    global function edit(qt::InstrQuantity, instrnm::String, addr::String, ::Val{:sweep})
        CImGui.PushStyleColor(
            CImGui.ImGuiCol_Button,
            if qt.isautorefresh || qt.issweeping
                MORESTYLE.Colors.DAQTaskRunning
            else
                CImGui.c_get(IMGUISTYLE.Colors, CImGui.ImGuiCol_Button)
            end
        )
        CImGui.PushStyleColor(
            CImGui.ImGuiCol_ButtonHovered,
            if qt.isautorefresh || qt.issweeping
                MORESTYLE.Colors.DAQTaskRunning
            else
                CImGui.c_get(IMGUISTYLE.Colors, CImGui.ImGuiCol_ButtonHovered)
            end
        )
        if CImGui.Button(qt.show_edit, (-1, 0))
            if addr != ""
                fetchdata = refresh_qt(instrnm, addr, qt.name)
                isnothing(fetchdata) || (qt.read = fetchdata)
                updatefront!(qt)
            end
        end
        CImGui.PopStyleColor(2)
        if CONF.InsBuf.showhelp && CImGui.IsItemHovered() && qt.help != ""
            ItemTooltip(qt.help)
        end
        if CImGui.BeginPopupContextItem()
            @c InputTextWithHintRSZ("##step", mlstr("step"), &qt.step)
            @c InputTextWithHintRSZ("##stop", mlstr("stop"), &qt.stop)
            @c CImGui.DragFloat("##delay", &qt.delay, 1.0, 0.05, 60, "%.3f", CImGui.ImGuiSliderFlags_AlwaysClamp)
            if qt.issweeping
                if CImGui.Button(mlstr(" Stop "), (-1, 0))
                    qt.issweeping = false
                    CImGui.CloseCurrentPopup()
                end
            else
                if CImGui.Button(mlstr(" Start "), (-1, 0)) || CImGui.IsKeyDown(257) || CImGui.IsKeyDown(335)
                    if addr != ""
                        Us = CONF.U[qt.utype]
                        U = isempty(Us) ? "" : Us[qt.uindex]
                        U == "" || (Uchange::Float64 = Us[1] isa Unitful.FreeUnits ? ustrip(Us[1], 1U) : 1.0)
                        start = remotecall_fetch(workers()[1], instrnm, addr) do instrnm, addr
                            ct = Controller(instrnm, addr)
                            try
                                getfunc = Symbol(instrnm, :_, qt.name, :_get) |> eval
                                login!(CPU, ct)
                                readstr = ct(getfunc, CPU, Val(:read))
                                logout!(CPU, ct)
                                return parse(Float64, readstr)
                            catch e
                                @error(
                                    "[$(now())]\n$(mlstr("error getting start value!!!"))",
                                    instrument = string(instrnm, "-", addr),
                                    exception = e
                                )
                                logout!(CPU, ct)
                            end
                        end
                        step = @trypasse eval(Meta.parse(qt.step)) * Uchange begin
                            @error "[$(now())]\n$(mlstr("error parsing step value!!!"))" step = qt.step
                        end
                        stop = @trypasse eval(Meta.parse(qt.stop)) * Uchange begin
                            @error "[$(now())]\n$(mlstr("error parsing stop value!!!"))" stop = qt.stop
                        end
                        if !(isnothing(start) || isnothing(step) || isnothing(stop))
                            if CONF.DAQ.equalstep
                                sweepsteps = ceil(Int, abs((start - stop) / step))
                                sweepsteps = sweepsteps == 1 ? 2 : sweepsteps
                                sweeplist = range(start, stop, length=sweepsteps)
                            else
                                step = start < stop ? abs(step) : -abs(step)
                                sweeplist = collect(start:step:stop)
                                sweeplist[end] == stop || push!(sweeplist, stop)
                            end
                            sweeptask = @async begin
                                qt.issweeping = true
                                ct = Controller(instrnm, addr)
                                try
                                    remotecall_wait(workers()[1], ct) do ct
                                        @isdefined(sweepcts) || (global sweepcts = Dict{UUID,Controller}())
                                        push!(sweepcts, ct.id => ct)
                                        login!(CPU, ct)
                                    end
                                    for i in sweeplist
                                        qt.issweeping || break
                                        sleep(qt.delay)
                                        qt.read = remotecall_fetch(workers()[1], i, ct.id) do i, ctid
                                            setfunc = Symbol(instrnm, :_, qt.name, :_set) |> eval
                                            getfunc = Symbol(instrnm, :_, qt.name, :_get) |> eval
                                            sweepcts[ctid](setfunc, CPU, string(i), Val(:write))
                                            return sweepcts[ctid](getfunc, CPU, Val(:read))
                                        end
                                    end
                                catch e
                                    @error(
                                        "[$(now())]\n$(mlstr("instrument communication failed!!!"))",
                                        instrument = string(instrnm, ": ", addr),
                                        quantity = qt.name,
                                        exception = e
                                    )
                                finally
                                    remotecall_wait(workers()[1], ct.id) do ctid
                                        logout!(CPU, sweepcts[ctid])
                                        pop!(sweepcts, ctid)
                                    end
                                end
                                qt.issweeping = false
                            end
                            errormonitor(sweeptask)
                        end
                    end
                    CImGui.CloseCurrentPopup()
                end
            end
            CImGui.Text(stcstr(mlstr("unit"), " "))
            CImGui.SameLine()
            CImGui.PushItemWidth(6CImGui.GetFontSize())
            @c ShowUnit("##insbuf", qt.utype, &qt.uindex)
            CImGui.PopItemWidth()
            CImGui.SameLine(0, 2CImGui.GetFontSize())
            @c CImGui.Checkbox(mlstr("refresh"), &qt.isautorefresh)
            CImGui.EndPopup()
            updatefront!(qt)
        end
        (qt.issweeping || qt.isautorefresh) && updatefront!(qt)
    end
end #let

let
    triggerset::Bool = false
    global function edit(qt::InstrQuantity, instrnm::String, addr::String, ::Val{:set})
        CImGui.PushStyleColor(
            CImGui.ImGuiCol_Button,
            qt.isautorefresh ? MORESTYLE.Colors.DAQTaskRunning : CImGui.c_get(IMGUISTYLE.Colors, CImGui.ImGuiCol_Button)
        )
        CImGui.PushStyleColor(
            CImGui.ImGuiCol_ButtonHovered,
            qt.isautorefresh ? MORESTYLE.Colors.DAQTaskRunning : CImGui.c_get(IMGUISTYLE.Colors, CImGui.ImGuiCol_ButtonHovered)
        )
        if CImGui.Button(qt.show_edit, (-1, 0))
            if addr != ""
                fetchdata = refresh_qt(instrnm, addr, qt.name)
                isnothing(fetchdata) || (qt.read = fetchdata)
                updatefront!(qt)
            end
        end
        CImGui.PopStyleColor(2)
        if CONF.InsBuf.showhelp && CImGui.IsItemHovered() && qt.help != ""
            ItemTooltip(qt.help)
        end
        if CImGui.BeginPopupContextItem()
            @c InputTextWithHintRSZ("##set", mlstr("set value"), &qt.set)
            if CImGui.Button(
                   stcstr(" ", mlstr("Confirm"), " "),
                   (-Cfloat(0.1), Cfloat(0))
               ) || triggerset || CImGui.IsKeyDown(257) || CImGui.IsKeyDown(335)
                triggerset = false
                if addr != ""
                    Us = CONF.U[qt.utype]
                    U = isempty(Us) ? "" : Us[qt.uindex]
                    U == "" || (Uchange::Float64 = Us[1] isa Unitful.FreeUnits ? ustrip(Us[1], 1U) : 1.0)
                    sv = U == "" ? qt.set : @trypasse string(float(eval(Meta.parse(qt.set)) * Uchange)) qt.set
                    triggerset && (sv = qt.optvalues[qt.optedidx])
                    fetchdata = remotecall_fetch(workers()[1], instrnm, addr, sv) do instrnm, addr, sv
                        ct = Controller(instrnm, addr)
                        try
                            setfunc = Symbol(instrnm, :_, qt.name, :_set) |> eval
                            getfunc = Symbol(instrnm, :_, qt.name, :_get) |> eval
                            login!(CPU, ct)
                            ct(setfunc, CPU, sv, Val(:write))
                            readstr = ct(getfunc, CPU, Val(:read))
                            logout!(CPU, ct)
                            return readstr
                        catch e
                            @error(
                                "[$(now())]\n$(mlstr("instrument communication failed!!!"))",
                                instrument = string(instrnm, ": ", addr),
                                quantity = qt.name,
                                exception = e
                            )
                            logout!(CPU, ct)
                        end
                    end
                    isnothing(fetchdata) || (qt.read = fetchdata)
                end
                CImGui.CloseCurrentPopup()
            end
            if addr != ""
                fetchdata = refresh_qt(instrnm, addr, qt.name)
                if !isnothing(fetchdata)
                    fetchdata in qt.optvalues && (qt.optedidx = findfirst(==(fetchdata), qt.optvalues))
                end
            end
            CImGui.BeginGroup()
            for (i, optv) in enumerate(qt.optvalues)
                (iseven(i) || optv == "") && continue
                @c(CImGui.RadioButton(qt.optkeys[i], &qt.optedidx, i)) && (qt.set = optv; triggerset = true)
            end
            CImGui.EndGroup()
            CImGui.SameLine(0, 2CImGui.GetFontSize())
            CImGui.BeginGroup()
            for (i, optv) in enumerate(qt.optvalues)
                (isodd(i) || optv == "") && continue
                @c(CImGui.RadioButton(qt.optkeys[i], &qt.optedidx, i)) && (qt.set = optv; triggerset = true)
            end
            CImGui.EndGroup()
            CImGui.Text(stcstr(mlstr("unit"), " "))
            CImGui.SameLine()
            CImGui.PushItemWidth(6CImGui.GetFontSize())
            @c ShowUnit("##insbuf", qt.utype, &qt.uindex)
            CImGui.PopItemWidth()
            CImGui.SameLine(0, 2CImGui.GetFontSize())
            @c CImGui.Checkbox(mlstr("refresh"), &qt.isautorefresh)
            CImGui.EndPopup()
            updatefront!(qt)
        end
        qt.isautorefresh && updatefront!(qt)
    end
end

let
    refbtsz::Float32 = 0
    global function edit(qt::InstrQuantity, instrnm, addr, ::Val{:read})
        CImGui.PushStyleColor(
            CImGui.ImGuiCol_Button,
            qt.isautorefresh ? MORESTYLE.Colors.DAQTaskRunning : CImGui.c_get(IMGUISTYLE.Colors, CImGui.ImGuiCol_Button)
        )
        CImGui.PushStyleColor(
            CImGui.ImGuiCol_ButtonHovered,
            qt.isautorefresh ? MORESTYLE.Colors.DAQTaskRunning : CImGui.c_get(IMGUISTYLE.Colors, CImGui.ImGuiCol_ButtonHovered)
        )
        if CImGui.Button(qt.show_edit, (-1, 0))
            if addr != ""
                fetchdata = refresh_qt(instrnm, addr, qt.name)
                isnothing(fetchdata) || (qt.read = fetchdata)
                updatefront!(qt)
            end
        end
        CImGui.PopStyleColor(2)
        if CONF.InsBuf.showhelp && CImGui.IsItemHovered() && qt.help != ""
            ItemTooltip(qt.help)
        end
        if CImGui.BeginPopupContextItem()
            CImGui.Text(stcstr(mlstr("unit"), " "))
            CImGui.SameLine()
            CImGui.PushItemWidth(6CImGui.GetFontSize())
            @c ShowUnit("##insbuf", qt.utype, &qt.uindex)
            CImGui.PopItemWidth()
            CImGui.SameLine(0, 2CImGui.GetFontSize())
            @c CImGui.Checkbox(mlstr("refresh"), &qt.isautorefresh)
            CImGui.EndPopup()
            updatefront!(qt)
        end
        qt.isautorefresh && updatefront!(qt)
    end
end

function view(instrbufferviewers_local)
    for ins in keys(instrbufferviewers_local)
        ins == "Others" && continue
        for (addr, ibv) in instrbufferviewers_local[ins]
            CImGui.TextColored(MORESTYLE.Colors.HighlightText, stcstr(ins, "：", addr))
            CImGui.PushID(addr)
            view(ibv.insbuf)
            CImGui.PopID()
        end
    end
end

function view(insbuf::InstrBuffer)
    y = ceil(Int, sum(qt.enable for (_, qt) in insbuf.quantities) / CONF.InsBuf.showcol) * 2CImGui.GetFrameHeight()
    CImGui.BeginChild("view insbuf", (Float32(0), y))
    CImGui.Columns(CONF.InsBuf.showcol, C_NULL, false)
    CImGui.PushID(insbuf.instrnm)
    for (name, qt) in insbuf.quantities
        qt.enable || continue
        CImGui.PushID(name)
        view(qt)
        CImGui.NextColumn()
        CImGui.PopID()
    end
    CImGui.PopID()
    CImGui.EndChild()
end

function view(qt::InstrQuantity)
    qt.show_view == "" && updatefront!(qt; show_edit=false)
    if CImGui.Button(qt.show_view, (-1, 0))
        Us = CONF.U[qt.utype]
        qt.uindex = (qt.uindex + 1) % length(Us)
        qt.uindex == 0 && (qt.uindex = length(Us))
        updatefront!(qt; show_edit=false)
    end
end

function refresh_qt(instrnm, addr, qtnm)
    remotecall_fetch(workers()[1], instrnm, addr) do instrnm, addr
        ct = Controller(instrnm, addr)
        try
            getfunc = Symbol(instrnm, :_, qtnm, :_get) |> eval
            login!(CPU, ct)
            readstr = ct(getfunc, CPU, Val(:read))
            logout!(CPU, ct)
            return readstr
        catch e
            @error(
                "[$(now())]\n$(mlstr("instrument communication failed!!!"))",
                instrument = string(instrnm, ": ", addr),
                quantity = qtnm,
                exception = e
            )
            logout!(CPU, ct)
        end
    end
end

function log_instrbufferviewers()
    manualrefresh()
    push!(CFGBUF, "instrbufferviewers/[$(now())]" => deepcopy(INSTRBUFFERVIEWERS))
end

function refresh_fetch_ibvs(ibvs_local; log=false)
    remotecall_fetch(workers()[1], ibvs_local, log, CONF.DAQ.logall) do ibvs_local, log, logall
        cts = Dict()
        @sync for ins in keys(ibvs_local)
            ins == "Others" && continue
            push!(cts, ins => Dict())
            for (addr, ibv) in ibvs_local[ins]
                push!(cts[ins], addr => Controller(ins, addr))
                @async begin
                    if ibv.insbuf.isautorefresh || log
                        try
                            login!(CPU, cts[ins][addr])
                            for (qtnm, qt) in ibv.insbuf.quantities
                                if (qt.isautorefresh && qt.enable) || (log && (logall || qt.enable))
                                    getfunc = Symbol(ins, :_, qtnm, :_get) |> eval
                                    qt.read = cts[ins][addr](getfunc, CPU, Val(:read))
                                elseif !qt.enable
                                    qt.read = ""
                                end
                            end
                            logout!(CPU, cts[ins][addr])
                        catch e
                            @error(
                                "[$(now())]\n$(mlstr("instrument communication failed!!!"))",
                                instrument = string(ins, ": ", addr),
                                exception = e
                            )
                            logout!(CPU, cts[ins][addr])
                            for (_, qt) in ibv.insbuf.quantities
                                qt.read = ""
                            end
                        end
                    end
                end
            end
        end
        return ibvs_local
    end
end

function manualrefresh()
    ibvs_remote = refresh_fetch_ibvs(INSTRBUFFERVIEWERS; log=true)
    for ins in keys(INSTRBUFFERVIEWERS)
        ins == "Others" && continue
        for (addr, ibv) in INSTRBUFFERVIEWERS[ins]
            for (qtnm, qt) in ibv.insbuf.quantities
                qt.read = ibvs_remote[ins][addr].insbuf.quantities[qtnm].read
            end
        end
    end
end

function autorefresh()
    errormonitor(
        @async while true
            i_sleep = 0
            while i_sleep < CONF.InsBuf.refreshrate
                sleep(0.1)
                i_sleep += 0.1
            end
            if SYNCSTATES[Int(IsAutoRefreshing)]
                ibvs_remote = refresh_fetch_ibvs(INSTRBUFFERVIEWERS)
                for ins in keys(INSTRBUFFERVIEWERS)
                    ins == "Others" && continue
                    for (addr, ibv) in INSTRBUFFERVIEWERS[ins]
                        if ibv.insbuf.isautorefresh
                            for (qtnm, qt) in ibv.insbuf.quantities
                                if qt.isautorefresh
                                    qt.read = ibvs_remote[ins][addr].insbuf.quantities[qtnm].read
                                end
                            end
                        end
                    end
                end
            end
        end
    )
end