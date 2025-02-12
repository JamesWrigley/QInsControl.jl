@kwdef mutable struct Layout
    id::String = "Layout"
    showcol::Cint = 3
    idxing::Cint = 1
    labels::Vector{String} = ["default"]
    marks::Vector{String} = [""]
    states::Vector{Bool} = [false]
    selectedlabels::Vector{String} = []
    labeltoidx::Dict{String,Int} = Dict()
    selectedidx::Vector{Int} = []
end

labeltoidx!(lo::Layout) = lo.selectedidx = [lo.labeltoidx[lb] for lb in lo.selectedlabels]

function edit(
    rightclickmenu,
    lo::Layout,
    size=(Cfloat(0), CImGui.GetFrameHeight() * ceil(Int, length(lo.labels) / lo.showcol));
    showlayout=true
)
    states_old = copy(lo.states)
    marks_old = copy(lo.marks)
    editlabels = @. lo.labels * " " * lo.marks * "###for rename" * lo.labels
    @c MultiSelectable(rightclickmenu, lo.id, editlabels, lo.states, lo.showcol, &lo.idxing, size)
    if lo.states != states_old || lo.marks != marks_old
        editlabels = @. lo.labels * " " * lo.marks
        lo.selectedlabels = editlabels[lo.states]
        lo.labeltoidx = Dict(zip(editlabels, collect(eachindex(editlabels))))
        labeltoidx!(lo)
    end
    if showlayout
        CImGui.Separator()
        CImGui.Text(mlstr("layout"))
        selectedlabels_old = copy(lo.selectedlabels)
        DragMultiSelectable(
            () -> false,
            lo.id,
            lo.selectedlabels,
            trues(length(lo.selectedlabels)),
            lo.showcol
        )
        lo.selectedlabels == selectedlabels_old || labeltoidx!(lo)
    end
end

function update!(lo::Layout)
    editlabels = @. lo.labels * " " * lo.marks
    lo.selectedlabels = editlabels[lo.states]
    lo.labeltoidx = Dict(zip(editlabels, collect(eachindex(editlabels))))
    labeltoidx!(lo)
    lo.idxing = 1
end

function Base.deleteat!(lo::Layout, i)
    deleteat!(lo.labels, i)
    deleteat!(lo.marks, i)
    deleteat!(lo.states, i)
    update!(lo)
end

@kwdef mutable struct DataPlot
    dtpks::Vector{DataPicker} = [DataPicker()]
    showdtpks::Vector{Bool} = [false]
    linkidx::Vector{Cint} = [0]
    uiplots::Vector{UIPlot} = [UIPlot()]
    layout::Layout = Layout()
    isdelplot::Bool = false
    delplot_i::Int = 0
end

function editmenu(dtp::DataPlot)
    if length(dtp.showdtpks) != length(dtp.dtpks)
        resize!(dtp.showdtpks, length(dtp.dtpks))
    end
    if length(dtp.linkidx) != length(dtp.dtpks)
        resize!(dtp.linkidx, length(dtp.dtpks))
        fill!(dtp.linkidx, 0)
    end
    if !CONF.DAQ.freelayout
        CImGui.Text(mlstr("plot columns"))
        CImGui.SameLine()
        CImGui.PushItemWidth(2CImGui.GetFontSize())
        @c CImGui.DragInt(
            "##plot columns",
            &CONF.DAQ.plotshowcol,
            1, 1, 6, "%d",
            CImGui.ImGuiSliderFlags_AlwaysClamp
        )
        CImGui.PopItemWidth()
        CImGui.SameLine()
    end
    CImGui.PushID("add new plot")
    if CImGui.Button(
        if CONF.DAQ.freelayout
            stcstr(MORESTYLE.Icons.NewFile, " ", mlstr("new plot"))
        else
            MORESTYLE.Icons.NewFile
        end
    )
        push!(dtp.layout.labels, string(length(dtp.layout.labels) + 1))
        push!(dtp.layout.marks, "")
        push!(dtp.layout.states, false)
        push!(dtp.uiplots, UIPlot())
        push!(dtp.dtpks, DataPicker())
        push!(dtp.linkidx, 0)
    end
    CImGui.PopID()

    dtp.layout.showcol = CONF.DAQ.freelayout ? 1 : CONF.DAQ.plotshowcol
    dtp.layout.labels = MORESTYLE.Icons.Plot * " " .*
                        string.(collect(eachindex(dtp.layout.labels)))
    maxplotmarkidx = argmax(lengthpr.(dtp.layout.marks))
    maxploticonwidth = CONF.DAQ.freelayout ? Cfloat(0) : dtp.layout.showcol * CImGui.CalcTextSize(
        stcstr(
            MORESTYLE.Icons.Plot,
            " ",
            dtp.layout.labels[maxplotmarkidx],
            dtp.layout.marks[maxplotmarkidx]
        )
    ).x
    edit(
        dtp.layout,
        (
            maxploticonwidth,
            CImGui.GetFrameHeight() * ceil(Int, length(dtp.layout.labels) /
                                                dtp.layout.showcol)
        );
        showlayout=!CONF.DAQ.freelayout
    ) do
        openright = CImGui.BeginPopupContextItem()
        if openright
            if CImGui.MenuItem(stcstr(MORESTYLE.Icons.Plot, " ", mlstr("Select Data")))
                dtp.layout.states[dtp.layout.idxing] || (dtp.dtpks[dtp.layout.idxing].isrealtime = false)
                dtp.showdtpks[dtp.layout.idxing] = true
            end
            if CImGui.MenuItem(stcstr(MORESTYLE.Icons.CloseFile, " ", mlstr("Delete")))
                dtp.isdelplot = true
                dtp.delplot_i = dtp.layout.idxing
            end
            markbuf = dtp.layout.marks[dtp.layout.idxing]
            CImGui.PushItemWidth(6CImGui.GetFontSize())
            @c InputTextRSZ(dtp.layout.labels[dtp.layout.idxing], &markbuf)
            CImGui.PopItemWidth()
            dtp.layout.marks[dtp.layout.idxing] = markbuf
            CImGui.Text(mlstr("Link to"))
            CImGui.SameLine()
            linkedidx = dtp.linkidx[dtp.layout.idxing]
            CImGui.PushItemWidth(4CImGui.GetFontSize())
            @c CImGui.DragInt(
                "##Link to", &linkedidx, 1, 0, length(dtp.dtpks), "%d",
                CImGui.ImGuiSliderFlags_AlwaysClamp
            )
            CImGui.PopItemWidth()
            dtp.linkidx[dtp.layout.idxing] = linkedidx
            CImGui.EndPopup()
        end
        # dealwithlinkidx(dtp)
        return openright
    end
end

function showdtpks(dtp::DataPlot, id, datastr::Dict, datafloat::Dict=Dict())
    if CImGui.BeginPopupModal(stcstr("no data", id), C_NULL, CImGui.ImGuiWindowFlags_AlwaysAutoResize)
        CImGui.TextColored(MORESTYLE.Colors.LogError, mlstr("no data!"))
        CImGui.Button(stcstr(mlstr("Confirm"), "##no data"), (180, 0)) && CImGui.CloseCurrentPopup()
        CImGui.EndPopup()
    end
    for (i, isshowdtpk) in enumerate(dtp.showdtpks)
        if isshowdtpk
            if isempty(datastr) && isempty(datafloat)
                CImGui.OpenPopup(stcstr("no data", id))
                dtp.showdtpks[i] = false
                continue
            end
            if dtp.linkidx[i] == 0
                dtpk = dtp.dtpks[i]
                datakeys = sort(collect(keys(isempty(datastr) ? datafloat : datastr)))
                if datakeys != dtpk.datalist
                    dtpk.datalist = collect(datakeys)
                    dtpk.y = falses(length(datakeys))
                    dtpk.w = falses(length(datakeys))
                end
                isupdate = @c edit(dtpk, stcstr(id, "-", i), &isshowdtpk)
                dtp.showdtpks[i] = isshowdtpk
                if isupdate || (dtpk.isrealtime && waittime(stcstr(id, "-", i, "-DataPicker"), dtpk.refreshrate))
                    syncplotdata(dtp.uiplots[i], dtpk, datastr, datafloat)
                end
            else
                dtpk = dtp.dtpks[i]
                uip = dtp.uiplots[dtp.linkidx[i]]
                dtpklink = dtp.dtpks[dtp.linkidx[i]]
                yl = length(uip.y)
                ykeys = "y" .* string.(1:yl)
                datakeys = ["x", ykeys..., "z"]
                if datakeys != dtpk.datalist
                    dtpk.datalist = collect(datakeys)
                    dtpk.y = falses(length(datakeys))
                    dtpk.w = falses(length(datakeys))
                end
                isupdate = @c edit(dtpk, stcstr(id, "-", i), &isshowdtpk)
                dtp.showdtpks[i] = isshowdtpk
                if isupdate || (dtpk.isrealtime && waittime(stcstr(id, "-", i, "-DataPicker"), dtpk.refreshrate))
                    linkeddata = Dict(
                        "x" => uip.x,
                        Dict("y$yi" => uip.y[yi] for yi in 1:yl)...,
                        "z" => copy(uip.z)
                    )
                    dtpklink.hflipz && reverse!(linkeddata["z"], dims=1)
                    dtpklink.vflipz && reverse!(linkeddata["z"], dims=2)
                    linkeddata["z"] = collect(transpose(linkeddata["z"]))
                    syncplotdata(dtp.uiplots[i], dtpk, Dict(), linkeddata)
                end
            end
        end
    end

    dtp.isdelplot && ((CImGui.OpenPopup(stcstr("##delete plot", dtp.layout.idxing)));
    dtp.isdelplot = false)
    if YesNoDialog(
        stcstr("##delete plot", dtp.layout.idxing),
        mlstr("Confirm delete?"),
        CImGui.ImGuiWindowFlags_AlwaysAutoResize
    )
        if length(dtp.uiplots) > 1
            deleteat!(dtp.layout, dtp.delplot_i)
            deleteat!(dtp.uiplots, dtp.delplot_i)
            deleteat!(dtp.dtpks, dtp.delplot_i)
            deleteat!(dtp.showdtpks, dtp.delplot_i)
            deleteat!(dtp.linkidx, dtp.delplot_i)
        end
    end
end

function renderplots(dtp::DataPlot, id)
    if CONF.DAQ.freelayout
        for (i, idx) in enumerate(dtp.layout.selectedidx)
            CImGui.SetNextWindowSize((600, 600), CImGui.ImGuiCond_Once)
            isopenplot = dtp.layout.states[idx]
            @c CImGui.Begin(
                stcstr(
                    MORESTYLE.Icons.Plot, " ",
                    mlstr("Plot"), " ",
                    idx, " ", dtp.layout.marks[idx],
                    "###", id, "-", idx, "dtv"
                ),
                &isopenplot
            )
            Plot(dtp.uiplots[idx], stcstr(id, "-", idx))
            CImGui.End()
            dtp.layout.states[idx] = isopenplot
            isopenplot || (deleteat!(dtp.layout.selectedidx, i); deleteat!(dtp.layout.selectedlabels, i))
        end
    else
        CImGui.BeginChild("plot")
        if isempty(dtp.layout.selectedidx)
            Plot(dtp.uiplots[1], stcstr(id, "-", 1))
        else
            totalsz = CImGui.GetContentRegionAvail()
            l = length(dtp.layout.selectedidx)
            n = CONF.DAQ.plotshowcol
            m = ceil(Int, l / n)
            n = m == 1 ? l : n
            height = (CImGui.GetContentRegionAvail().y - (m - 1) * unsafe_load(IMGUISTYLE.ItemSpacing.y)) / m
            for i in 1:m
                CImGui.BeginChild(stcstr("plotrow", i), (Cfloat(0), height))
                CImGui.Columns(n)
                for j in 1:n
                    idx = (i - 1) * n + j
                    if idx <= l
                        index = dtp.layout.selectedidx[idx]
                        Plot(dtp.uiplots[index], stcstr(id, "-", index), (Cfloat(0), height))
                        CImGui.NextColumn()
                    end
                end
                CImGui.EndChild()
            end
        end
        CImGui.EndChild()
    end
end

# function dealwithlinkidx(dtviewer::DataViewer)
#     for (i, idx) in enumerate(dtviewer.linkidx)
#         if idx == 0
#             if occursin("------>", dtviewer.layout.marks[i])
#                 dtviewer.layout.marks[i] = replace(dtviewer.layout.marks[i], r" ------> \w" => "")
#             end
#         else
#             if occursin(" ------> $idx", dtviewer.layout.marks[i])
#                 continue
#             elseif occursin(" ------> ", dtviewer.layout.marks[i])
#                 dtviewer.layout.marks[i] = replace(dtviewer.layout.marks[i], r" ------> \w" => " ------> $idx")
#             else
#                 dtviewer.layout.marks[i] *= " ------> $idx"
#             end
#         end
#     end
# end