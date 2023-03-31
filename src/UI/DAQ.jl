let
    firsttime::Bool = true
    show_daq_editor::Bool = false
    show_daq_editor_i::Int = 0
    show_daq_selector::Bool = false
    show_daq_selector_i::Int = 0
    show_plot_num::Cint = 1
    isdeldaqtask::Bool = false
    isrename::Bool = false
    showdisabled::Bool = false
    isdelall::Bool = false
    oldworkpath::String = ""
    running_i::Int = 0
    isrunall::Bool = false
    global daqtasks::Vector{DAQTask} = [DAQTask()] #任务列表
    global uipsweeps::Vector{UIPlot} = [UIPlot() for i in 1:4] #绘图缓存
    global daq_dtpks::Vector{DataPicker} = [DataPicker() for i in 1:4] #绘图数据选择

    taskbt_ids::Dict{Tuple{Int,String},String} = Dict()
    editmenu_ids::Dict{Int,String} = Dict()
    yesnodialog_ids::Dict{Int,String} = Dict()
    rename_ids::Dict{Int,String} = Dict()
    waittimedaq_ids::Dict{Int,String} = Dict()
    global function DAQ(p_open::Ref)
        # CImGui.SetNextWindowPos((300, 100), CImGui.ImGuiCond_Once)
        # CImGui.SetNextWindowSize((1400, 900), CImGui.ImGuiCond_Once)
        isinner = false
        if CImGui.Begin(morestyle.Icons.InstrumentsDAQ * "  数据采集", p_open)
            global workpath
            global savepath
            global old_i
            CImGui.Button(morestyle.Icons.SelectPath * " 工作区 ") && (workpath = pick_folder())
            CImGui.SameLine()
            txtc = workpath == "未选择工作区！！！" ? ImVec4(morestyle.Colors.LogError...) : CImGui.c_get(imguistyle.Colors, CImGui.ImGuiCol_Text)
            CImGui.TextColored(txtc, workpath)
            if workpath != oldworkpath
                if isdir(workpath)
                    oldworkpath = workpath
                    date = today()
                    find_old_i(joinpath(workpath, string(year(date)), string(year(date), "-", month(date)), string(date)))
                else
                    old_i = 0
                end
            end
            CImGui.Separator()
            CImGui.Columns(2)
            firsttime && (CImGui.SetColumnOffset(1, CImGui.GetWindowWidth() * 0.25); firsttime = false)
            CImGui.BeginChild("队列", (Float32(0), -CImGui.GetFrameHeightWithSpacing()))
            CImGui.BulletText("任务队列")
            isinner = isinner || CImGui.IsItemHovered()
            for (i, task) in enumerate(daqtasks)
                task.enable || showdisabled || continue
                CImGui.PushID(i)
                buf = task.name
                isrunning_i = syncstates[Int(isdaqtask_running)] && i == running_i
                btc = isrunning_i ? ImVec4(morestyle.Colors.DAQTaskRunning...) : CImGui.c_get(imguistyle.Colors, CImGui.ImGuiCol_Button)
                btc = task.enable ? btc : ImVec4(morestyle.Colors.LogError...)
                CImGui.PushStyleColor(CImGui.ImGuiCol_Button, btc)
                haskey(taskbt_ids, (i + old_i, buf)) || push!(taskbt_ids, (i + old_i, buf) => morestyle.Icons.TaskButton * " 任务 $(i+old_i) $buf###rename")
                CImGui.Button(taskbt_ids[(i + old_i, buf)], (-1, 0)) && (show_daq_editor_i = i; show_daq_editor = true)
                # CImGui.Button(" 任务 $(i+old_i) $buf###rename", (-1, 0)) && (show_daq_editor_i = i; show_daq_editor = true)
                CImGui.PopStyleColor()
                haskey(editmenu_ids, i) || push!(editmenu_ids, i => "队列编辑菜单$i")
                CImGui.OpenPopupOnItemClick(editmenu_ids[i], 1)
                isrunning_i && ShowProgressBar()
                show_daq_editor && show_daq_editor_i == i && @c edit(task, i, &show_daq_editor)
                isinner = isinner || CImGui.IsItemHovered()
                if !syncstates[Int(isdaqtask_running)]
                    CImGui.Indent()
                    if CImGui.BeginDragDropSource(0)
                        @c CImGui.SetDragDropPayload("Swap DAQTask", &i, sizeof(Cint))
                        CImGui.EndDragDropSource()
                    end
                    if CImGui.BeginDragDropTarget()
                        payload = CImGui.AcceptDragDropPayload("Swap DAQTask")
                        if payload != C_NULL && unsafe_load(payload).DataSize == sizeof(Cint)
                            payload_i = unsafe_load(Ptr{Cint}(unsafe_load(payload).Data))
                            if i != payload_i
                                insert!(daqtasks, i, daqtasks[payload_i])
                                payload_i < i ? deleteat!(daqtasks, payload_i) : deleteat!(daqtasks, payload_i + 1)
                            end
                        end
                        CImGui.EndDragDropTarget()
                    end
                    CImGui.Unindent()
                end

                if CImGui.BeginPopup(editmenu_ids[i])
                    if CImGui.MenuItem(morestyle.Icons.RunTask * " 运行", C_NULL, false, !syncstates[Int(isdaqtask_running)] && task.enable)
                        if ispath(workpath)
                            running_i = i
                            errormonitor(@async begin
                                run(task)
                                syncstates[Int(isinterrupt)] && (syncstates[Int(isinterrupt)] = false)
                            end)
                            show_daq_selector = false
                        else
                            workpath = "未选择工作区！！！"
                        end
                    end
                    CImGui.Separator()
                    CImGui.MenuItem(morestyle.Icons.Edit * " 编辑") && (show_daq_editor_i = i; show_daq_editor = true)
                    CImGui.MenuItem(morestyle.Icons.Copy * " 复制") && (insert!(daqtasks, i + 1, deepcopy(task)))
                    if CImGui.MenuItem(morestyle.Icons.SaveButton * " 保存")
                        confsvpath = save_file(filterlist="cfg")
                        isempty(confsvpath) || jldsave(confsvpath; daqtask=task)
                    end
                    if CImGui.MenuItem(morestyle.Icons.Load * " 加载")
                        confldpath = pick_file(filterlist="cfg;qdt")
                        if isfile(confldpath)
                            loadcfg = @trypass load(confldpath, "daqtask") (@error "不支持的文件！！！" filepath = confldpath)
                            daqtasks[i] = isnothing(loadcfg) ? task : loadcfg
                        end
                    end
                    CImGui.Separator()
                    CImGui.MenuItem(morestyle.Icons.Rename * " 重命名") && (isrename = true)
                    if task.enable
                        CImGui.MenuItem(morestyle.Icons.Disable * " 停用") && (task.enable = false)
                    else
                        CImGui.MenuItem(morestyle.Icons.Restore * " 恢复") && (task.enable = true)
                        CImGui.MenuItem(morestyle.Icons.CloseFile * " 删除") && (isdeldaqtask = true)
                    end
                    CImGui.EndPopup()
                end

                # 是否删除
                haskey(yesnodialog_ids, i) || push!(yesnodialog_ids, i => "##是否删除daqtasks$i")
                isdeldaqtask && (CImGui.OpenPopup(yesnodialog_ids[i]);
                isdeldaqtask = false)
                YesNoDialog(yesnodialog_ids[i], "确认删除？", CImGui.ImGuiWindowFlags_AlwaysAutoResize) && deleteat!(daqtasks, i)

                # 重命名
                haskey(rename_ids, i) || push!(rename_ids, i => "重命名$i")
                isrename && (CImGui.OpenPopup(rename_ids[i]);
                isrename = false)
                if CImGui.BeginPopup(rename_ids[i])
                    @c InputTextRSZ(morestyle.Icons.TaskButton * " 任务 $(i+old_i) ", &task.name)
                    CImGui.EndPopup()
                end
                CImGui.PopID()
            end
            CImGui.EndChild()
            if CImGui.BeginPopup("添加队列")
                CImGui.MenuItem(morestyle.Icons.NewFile * " 添加") && push!(daqtasks, DAQTask())
                if CImGui.MenuItem(morestyle.Icons.Load * " 加载")
                    confldpath = pick_file(filterlist="cfg")
                    if isfile(confldpath)
                        newdaqtask = @trypasse load(confldpath, "daqtask") (@error "不支持的文件！！！" filepath = confldpath)
                        isnothing(newdaqtask) || push!(daqtasks, newdaqtask)
                    end
                end
                CImGui.Separator()
                if showdisabled
                    CImGui.MenuItem(morestyle.Icons.NotShowDisable * " 隐藏不可用") && (showdisabled = false)
                    CImGui.MenuItem(morestyle.Icons.CloseFile * " 删除不可用") && (isdelall = true)
                else
                    CImGui.MenuItem(morestyle.Icons.ShowDisable * " 显示不可用") && (showdisabled = true)
                end
                if CImGui.MenuItem(morestyle.Icons.SaveButton * " 保存项目")
                    daqsvpath = save_file(filterlist="daq")
                    isempty(daqsvpath) || jldsave(daqsvpath; daqtasks=daqtasks)
                end
                if CImGui.MenuItem(morestyle.Icons.Load * " 加载项目")
                    daqloadpath = pick_file(filterlist="daq")
                    if isfile(daqloadpath)
                        loaddaqtasks = @trypasse load(daqloadpath, "daqtasks") (@error "不支持的文件！！！" filepath = daqloadpath)
                        isnothing(loaddaqtasks) || (empty!(daqtasks);
                        for task in loaddaqtasks
                            push!(daqtasks, task)
                        end)
                    end
                end
                CImGui.Separator()
                # CImGui.MenuItem("选择数据") && (show_daq_selector = true)
                if CImGui.BeginMenu(morestyle.Icons.PlotNumber * " 绘图数量")
                    CImGui.PushItemWidth(4CImGui.GetFontSize())
                    @c CImGui.DragInt("绘图数量", &show_plot_num, 1, 1, 4, "%d", CImGui.ImGuiSliderFlags_AlwaysClamp)
                    CImGui.PopItemWidth()
                    CImGui.EndMenu()
                end
                if CImGui.BeginMenu(morestyle.Icons.SelectData * " 选择数据")
                    for i in 1:show_plot_num
                        CImGui.MenuItem(morestyle.Icons.Datai * " 绘图$i") && (show_daq_selector = true; show_daq_selector_i = i)
                    end
                    CImGui.EndMenu()
                end

                CImGui.EndPopup()
            end
            isdelall && (CImGui.OpenPopup("##删除所有不可用task");
            isdelall = false)
            YesNoDialog("##删除所有不可用task", "确认删除？", CImGui.ImGuiWindowFlags_AlwaysAutoResize) && deleteat!(daqtasks, findall(task -> !task.enable, daqtasks))
            !isinner && CImGui.OpenPopupOnItemClick("添加队列", 1)
            runallbtc = isrunall ? ImVec4(morestyle.Colors.DAQTaskRunning...) : CImGui.c_get(imguistyle.Colors, CImGui.ImGuiCol_Button)
            CImGui.PushStyleColor(CImGui.ImGuiCol_Button, runallbtc)
            if CImGui.Button(morestyle.Icons.RunTask * " 全部运行")
                if !syncstates[Int(isdaqtask_running)]
                    if ispath(workpath)
                        runalltask = @async begin
                            isrunall = true
                            for (i, task) in enumerate(daqtasks)
                                running_i = i
                                run(task)
                                syncstates[Int(isinterrupt)] && (syncstates[Int(isinterrupt)] = false; break)
                            end
                            isrunall = false
                        end
                        errormonitor(runalltask)
                        show_daq_selector = false
                    else
                        workpath = "未选择工作区！！！"
                    end
                end
            end
            CImGui.PopStyleColor()

            @cstatic btsz::Float32 = 0 begin
                CImGui.SameLine(CImGui.GetColumnOffset(1) - btsz - unsafe_load(imguistyle.WindowPadding.x))
                if syncstates[Int(isblock)]
                    if CImGui.Button(morestyle.Icons.RunTask * " 继续")
                        syncstates[Int(isblock)] = false
                        remote_do(workers()[1]) do
                            lock(() -> notify(block), block)
                        end
                    end
                else
                    CImGui.Button(morestyle.Icons.BlockTask * " 暂停") && (syncstates[Int(isdaqtask_running)] && (syncstates[Int(isblock)] = true))
                end
                btsz = CImGui.GetItemRectSize().x
                CImGui.SameLine(0, 0)
                if CImGui.Button(morestyle.Icons.InterruptTask * " 中断")
                    if syncstates[Int(isdaqtask_running)]
                        syncstates[Int(isinterrupt)] = true
                        if syncstates[Int(isblock)]
                            syncstates[Int(isblock)] = false
                            remote_do(workers()[1]) do
                                lock(() -> notify(block), block)
                            end
                        end
                    end
                end
                btsz += CImGui.GetItemRectSize().x
            end

            if show_daq_selector
                daq_dtpk = daq_dtpks[show_daq_selector_i]
                datakeys::Set{String} = keys(databuf)
                datakeys == Set(daq_dtpk.datalist) || (daq_dtpk.datalist = collect(datakeys); daq_dtpk.y = falses(length(datakeys)))
                isupdate = @c edit(daq_dtpk, "DAQ", &show_daq_selector)
                !show_daq_selector || isupdate && syncplotdata(uipsweeps[show_daq_selector_i], daq_dtpk, databuf)
            end
            for i in 1:show_plot_num
                if daq_dtpks[i].isrealtime
                    haskey(waittimedaq_ids, i) || push!(waittimedaq_ids, i => "DAQ$i")
                    waittime(waittimedaq_ids[i], daq_dtpks[i].refreshrate) && syncplotdata(uipsweeps[i], daq_dtpks[i], databuf)
                end
            end

            CImGui.NextColumn()

            CImGui.BeginChild("绘图")
            totalsz = CImGui.GetContentRegionAvail()
            if show_plot_num == 1
                Plot(uipsweeps[1], "扫描实时绘图1")
            elseif show_plot_num == 2
                CImGui.Columns(2)
                Plot(uipsweeps[1], "扫描实时绘图1")
                CImGui.NextColumn()
                Plot(uipsweeps[2], "扫描实时绘图2")
                CImGui.NextColumn()
            elseif show_plot_num == 3
                CImGui.Columns(2)
                Plot(uipsweeps[1], "扫描实时绘图1", (Float32(0), totalsz.y / 2))
                CImGui.NextColumn()
                Plot(uipsweeps[2], "扫描实时绘图2", (Float32(0), totalsz.y / 2))
                CImGui.NextColumn()
                Plot(uipsweeps[3], "扫描实时绘图3")
                CImGui.NextColumn()
            elseif show_plot_num == 4
                CImGui.Columns(2)
                Plot(uipsweeps[1], "扫描实时绘图1", (Float32(0), totalsz.y / 2))
                CImGui.NextColumn()
                Plot(uipsweeps[2], "扫描实时绘图2", (Float32(0), totalsz.y / 2))
                CImGui.NextColumn()
                Plot(uipsweeps[3], "扫描实时绘图3")
                CImGui.NextColumn()
                Plot(uipsweeps[4], "扫描实时绘图4")
                CImGui.NextColumn()
            end
            CImGui.EndChild()
            CImGui.NextColumn()
        end
        CImGui.End()
    end
end #let

function find_old_i(dir)
    global old_i
    if isdir(dir)
        for file in readdir(dir) # 任务顺序根据文件夹内容确定
            if isfile(joinpath(dir, file))
                m = match(r"任务 ([0-9]+)", file)
                if !isnothing(m)
                    new_i = tryparse(Int, m[1])
                    isnothing(new_i) || (old_i = new_i > old_i ? new_i : old_i)
                end
            end
        end
    else
        old_i = 0
    end
    nothing
end

function ShowProgressBar()
    for pgb in values(progresslist)
        pgmark = string(pgb[2], "/", pgb[3], "(", tohms(pgb[4]), "/", tohms(pgb[3] * pgb[4] / pgb[2]), ")")
        if pgb[2] == pgb[3]
            delete!(progresslist, pgb[1])
        else
            CImGui.ProgressBar(pgb[2] / pgb[3], (-1, 0), pgmark)
        end
    end
end