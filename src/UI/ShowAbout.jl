function ShowAbout()
    if CImGui.BeginPopupModal(mlstr("About"), C_NULL, CImGui.ImGuiWindowFlags_AlwaysAutoResize)
        ftsz = CImGui.GetFontSize()
        ww = CImGui.GetWindowWidth()
        CImGui.SameLine(ww / 3)
        CImGui.Image(Ptr{Cvoid}(ICONID), (ww / 3, ww / 3))
        CImGui.Text("\n")
        CImGui.Text("")
        CImGui.SameLine(ww / 2 - 2.5ftsz)
        CImGui.TextColored(MORESTYLE.Colors.HighlightText, "QInsControl\n\n")
        CImGui.Text(stcstr(mlstr("version"), " : 0.1.0"))
        CImGui.Text(stcstr(mlstr("author"), " : XST\n\n"))
        global JLVERINFO
        CImGui.Text(JLVERINFO)
        CImGui.Text("\n")
        CImGui.Button(stcstr(mlstr("Confirm"), "##ShowAbout"), (-1, 0)) && CImGui.CloseCurrentPopup()
        CImGui.EndPopup()
    end
end
