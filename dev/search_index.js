var documenterSearchIndex = {"docs":
[{"location":"QInsControlCore/#QInsControl.QInsControlCore","page":"QInsControlCore","title":"QInsControl.QInsControlCore","text":"","category":"section"},{"location":"QInsControlCore/","page":"QInsControlCore","title":"QInsControlCore","text":"","category":"page"},{"location":"QInsControlCore/","page":"QInsControlCore","title":"QInsControlCore","text":"Modules = [QInsControl.QInsControlCore]","category":"page"},{"location":"QInsControlCore/#QInsControl.QInsControlCore.Controller","page":"QInsControlCore","title":"QInsControl.QInsControlCore.Controller","text":"Controller(instrnm, addr)\n\nconstruct a Controller to send commands to the instrument determined by (instrnm, addr). A Controller has three ways to send commands to the Processor: wirte read query.\n\njulia> ct(write, cpu, \"*IDN?\", Val(:write))\n\"done\"\n\njulia> ct(read, cpu, Val(:read))\n\"read\"\n\njulia> ct(query, cpu, \"*IDN?\", Val(:query))\n\"query\"\n\nthe commands needed to execute is not necessary to be wirte, read or query.\n\njulia> idn_get(instr) = query(instr, \"*IDN?\")\nidn_get (generic function with 1 method)\n\njulia> ct(idn_get, cpu, Val(:read))\n\"query\"\n\nthe definition of function idn_get must happen before the Controller ct is logged in or one can log out and log in again.\n\n\n\n\n\n","category":"type"},{"location":"QInsControlCore/#QInsControl.QInsControlCore.Processor","page":"QInsControlCore","title":"QInsControl.QInsControlCore.Processor","text":"Processor()\n\nconstruct a Processor to deal with the commands sended into by Controllers.\n\n\n\n\n\n","category":"type"},{"location":"QInsControlCore/#Base.read-Tuple{QInsControl.QInsControlCore.GPIBInstr}","page":"QInsControlCore","title":"Base.read","text":"read(instr)\n\nread the instrument.\n\n\n\n\n\n","category":"method"},{"location":"QInsControlCore/#Base.write-Tuple{QInsControl.QInsControlCore.GPIBInstr, AbstractString}","page":"QInsControlCore","title":"Base.write","text":"write(instr, msg)\n\nwrite some message string to the instrument.\n\n\n\n\n\n","category":"method"},{"location":"QInsControlCore/#QInsControl.QInsControlCore.connect!-Tuple{Any, QInsControl.QInsControlCore.GPIBInstr}","page":"QInsControlCore","title":"QInsControl.QInsControlCore.connect!","text":"connect!(rm, instr)\n\nconnect to an instrument with given ResourceManager rm.\n\nconnect!(instr)\n\nsame but with auto-generated ResourceManager.\n\n\n\n\n\n","category":"method"},{"location":"QInsControlCore/#QInsControl.QInsControlCore.disconnect!-Tuple{QInsControl.QInsControlCore.GPIBInstr}","page":"QInsControlCore","title":"QInsControl.QInsControlCore.disconnect!","text":"disconnect!(instr)\n\ndisconnect the instrument.\n\n\n\n\n\n","category":"method"},{"location":"QInsControlCore/#QInsControl.QInsControlCore.fast!-Tuple{QInsControl.QInsControlCore.Processor}","page":"QInsControlCore","title":"QInsControl.QInsControlCore.fast!","text":"fast!(cpu::Processor)\n\nchange the cpu mode to fast mode. Default mode is slow mode. The fast mode is not necessary in most cases.\n\n\n\n\n\n","category":"method"},{"location":"QInsControlCore/#QInsControl.QInsControlCore.find_resources-Tuple{QInsControl.QInsControlCore.Processor}","page":"QInsControlCore","title":"QInsControl.QInsControlCore.find_resources","text":"find_resources(cpu::Processor)\n\nauto-detect available instruments.\n\n\n\n\n\n","category":"method"},{"location":"QInsControlCore/#QInsControl.QInsControlCore.instrument-Tuple{Any, Any}","page":"QInsControlCore","title":"QInsControl.QInsControlCore.instrument","text":"instrument(name, addr)\n\ngenerate an instrument with (name, addr) which automatically determines the type of this instrument.\n\n\n\n\n\n","category":"method"},{"location":"QInsControlCore/#QInsControl.QInsControlCore.isconnected-Tuple{QInsControl.QInsControlCore.GPIBInstr}","page":"QInsControlCore","title":"QInsControl.QInsControlCore.isconnected","text":"isconnected(instr)\n\ndetermine if the instrument is connected.\n\n\n\n\n\n","category":"method"},{"location":"QInsControlCore/#QInsControl.QInsControlCore.login!-Tuple{QInsControl.QInsControlCore.Processor, QInsControl.QInsControlCore.Controller}","page":"QInsControlCore","title":"QInsControl.QInsControlCore.login!","text":"login!(cpu::Processor, ct::Controller)\n\nlog the Controller in the Processor which can be done before and after the cpu started.\n\n\n\n\n\n","category":"method"},{"location":"QInsControlCore/#QInsControl.QInsControlCore.logout!-Tuple{QInsControl.QInsControlCore.Processor, QInsControl.QInsControlCore.Controller}","page":"QInsControlCore","title":"QInsControl.QInsControlCore.logout!","text":"logout!(cpu::Processor, ct::Controller)\n\nlog the Controller out the Processor.\n\nlogout!(cpu::Processor, addr::String)\n\nlog all the Controllers that control the instrument with address addr out the Processor.\n\n\n\n\n\n","category":"method"},{"location":"QInsControlCore/#QInsControl.QInsControlCore.query-Tuple{QInsControl.QInsControlCore.GPIBInstr, AbstractString}","page":"QInsControlCore","title":"QInsControl.QInsControlCore.query","text":"query(instr, msg; delay=0)\n\nquery the instrument with some message string.\n\n\n\n\n\n","category":"method"},{"location":"QInsControlCore/#QInsControl.QInsControlCore.reconnect!-Tuple{QInsControl.QInsControlCore.Processor}","page":"QInsControlCore","title":"QInsControl.QInsControlCore.reconnect!","text":"reconnect!(cpu::Processor)\n\nreconnect the instruments that log in the Processor.\n\n\n\n\n\n","category":"method"},{"location":"QInsControlCore/#QInsControl.QInsControlCore.slow!-Tuple{QInsControl.QInsControlCore.Processor}","page":"QInsControlCore","title":"QInsControl.QInsControlCore.slow!","text":"slow!(cpu::Processor)\n\nchange the cpu mode to slow mode. Default mode is slow mode, which decrease the cpu cost.\n\n\n\n\n\n","category":"method"},{"location":"QInsControlCore/#QInsControl.QInsControlCore.start!-Tuple{QInsControl.QInsControlCore.Processor}","page":"QInsControlCore","title":"QInsControl.QInsControlCore.start!","text":"start!(cpu::Processor)\n\nstart the Processor.\n\n\n\n\n\n","category":"method"},{"location":"QInsControlCore/#QInsControl.QInsControlCore.stop!-Tuple{QInsControl.QInsControlCore.Processor}","page":"QInsControlCore","title":"QInsControl.QInsControlCore.stop!","text":"stop!(cpu::Processor)\n\nstop the Processor.\n\n\n\n\n\n","category":"method"},{"location":"Workflow/#Add-Instruments","page":"Workflow","title":"Add Instruments","text":"","category":"section"},{"location":"Workflow/#auto-detect","page":"Workflow","title":"auto-detect","text":"","category":"section"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"One can click on \"自动查询\" to auto-detect the available instruments in NI MAX. ","category":"page"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"(Image: image)","category":"page"},{"location":"Workflow/#muanully-add","page":"Workflow","title":"muanully add","text":"","category":"section"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"Or manually add an instrument through clicking on \"手动输入\" after filling the address and clicking on \"添加\" in the end. ","category":"page"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"(Image: image)","category":"page"},{"location":"Workflow/#Control-the-Instruments","page":"Workflow","title":"Control the Instruments","text":"","category":"section"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"Once adding instruments finishes, one can click \"仪器设置和状态\" to query the state of specific instrument or set it. The controllable variables are classified by three types: sweep, set, read. ","category":"page"},{"location":"Workflow/#sweep","page":"Workflow","title":"sweep","text":"","category":"section"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"For the sweepable variables, it can be swept from the present value to the given value with difinite step size and delay.","category":"page"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"(Image: image)","category":"page"},{"location":"Workflow/#set","page":"Workflow","title":"set","text":"","category":"section"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"For the settable variables, it can be set by the given value through inputing or simply clicking on a pre-defined optional  value.","category":"page"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"(Image: image)","category":"page"},{"location":"Workflow/#read","page":"Workflow","title":"read","text":"","category":"section"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"For the readable variables, it can be only queried.","category":"page"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"(Image: image)","category":"page"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"All these variables support selecting unit and whether it will auto update the state itself.","category":"page"},{"location":"Workflow/#Data-Aquiring","page":"Workflow","title":"Data Aquiring","text":"","category":"section"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"Clicking on \"仪器 -> 数据采集\" to do data aquiring","category":"page"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"(Image: image)","category":"page"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"\"工作区\" : select root folder for saving data. Data will be stored as","category":"page"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"root folder/year/month/day/[time] task name.qdt","category":"page"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"\"任务 1\" : represent a task script to aquire data. One can click it to edit the script or right click for more options.","category":"page"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"microchip : click it to edit circuit for recording measurement configuration.","category":"page"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"\"全部运行\" : run all the available tasks in a top-down order","category":"page"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"\"暂停\" : suspend the running task","category":"page"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"\"中断\" : stop the running task","category":"page"},{"location":"Workflow/#Edit-script","page":"Workflow","title":"Edit script","text":"","category":"section"},{"location":"Workflow/#CodeBlock","page":"Workflow","title":"CodeBlock","text":"","category":"section"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"(Image: image)","category":"page"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"It can be input with any julia codes. It is helpful when dealing with complicated relation between variables and it supports all the grammar of julia language.","category":"page"},{"location":"Workflow/#StrideCodeBlock","page":"Workflow","title":"StrideCodeBlock","text":"","category":"section"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"(Image: image)","category":"page"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"It is similar to CodeBlock, but it can only be input a block title codes such as for end, begin end, function end and so on. It is used to combine block codes in julia with other blocks in QInsControl.","category":"page"},{"location":"Workflow/#SweepBlock","page":"Workflow","title":"SweepBlock","text":"","category":"section"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"(Image: image)","category":"page"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"It is used to sweep a sweepable quantity. One can click to select the specific instrument, address and quantity and input step, destination and delay. A sweepable quantity is generally dimensioned and one have to make sure that a  correct unit is selected.","category":"page"},{"location":"Workflow/#SettingBlock","page":"Workflow","title":"SettingBlock","text":"","category":"section"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"(Image: image)","category":"page"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"Similar to SweepBlock but for a settable quantity (a sweepable quantity is also a settable quantity). One can input a string or a number dependent on the unit. When unit type is none, it only supports a string input and a \"$(Expr(:incomplete, \"incomplete: invalid string syntax\"))","category":"page"},{"location":"Workflow/#ReadingBlock","page":"Workflow","title":"ReadingBlock","text":"","category":"section"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"(Image: image)","category":"page"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"\"索引\" is used to split the data by \",\". When data do not include delimiter, leave it blank. \"标注\" is used to name the  recorded data. When data format includes delimiter, one can use \",\" to seperate multiple marks.","category":"page"},{"location":"Workflow/#LogBlock","page":"Workflow","title":"LogBlock","text":"","category":"section"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"(Image: image)","category":"page"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"When it is executed, all the available instruments will be logged. (before and after script runing, a logging action  will happen, so it is not necessary to add this block in the first and last line of a script)","category":"page"},{"location":"Workflow/#WriteBlock","page":"Workflow","title":"WriteBlock","text":"","category":"section"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"(Image: image)","category":"page"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"Input the command and write to the specified instrument.","category":"page"},{"location":"Workflow/#QueryBlock","page":"Workflow","title":"QueryBlock","text":"","category":"section"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"(Image: image)","category":"page"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"Input the command and query the specified instrument.","category":"page"},{"location":"Workflow/#ReadBlock","page":"Workflow","title":"ReadBlock","text":"","category":"section"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"(Image: image)","category":"page"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"Read the specified instrument.","category":"page"},{"location":"Workflow/#SaveBlock","page":"Workflow","title":"SaveBlock","text":"","category":"section"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"(Image: image)","category":"page"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"It is used to save a variable defined in the context. \"标注\" is an optional input to specify the name to be stored. When it is blank, the name will be the same as the variable.","category":"page"},{"location":"Workflow/#note","page":"Workflow","title":"note","text":"","category":"section"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"All the blocks that bind to a specified instrument can be middle clicked to enter catch mode. In this mode, the icon is  red and the data obtained will be a \"\" when an error occurs. For ReadingBlock, QueryBlock and ReadBlock, middle clicking at the region used to input marks will change the mode from normal to observable to observable and readable. In  observable mode, the mark region is cyan and the obtained data will be stored in a variable named by the input marks and will not be stored in file. In observable and readable region, the mark region is red, all same as observable mode but the obtained data will stored in file. For ReadingBlock, WriteBlock, QueryBlock and ReadBlock, clicking on the block border will enter the async mode. In this mode, block border is green and the generated codes will be marked by @async, this almost always speeds up the measurement.","category":"page"},{"location":"Workflow/#Example","page":"Workflow","title":"Example","text":"","category":"section"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"(Image: image)","category":"page"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"This panel includes a title of the editing task, a \"HOLD\" checkbox to set the panel no-close when selected, an inputable region to record something necessary, a button \"刷新仪器列表\" with the same functionality as previous menu, an \"Edit\" or  \"View\" checkbox to change the editing mode and finally a region to write your own script.","category":"page"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"This script includes two loop structures. The outter one is constructed by a StrideCodeBlock with code","category":"page"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"@progress for i in 1:2","category":"page"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"on it. The macro @progress is used to show a progressbar. The inner one is constructed by a SweepBlock. It relates to the instrument VirtualInstr with address VirtualAddress, variable \"扫描测试\", step 1 μA, destination 200 μA and delay  0.1s for each loop.","category":"page"},{"location":"Workflow/#plot-data","page":"Workflow","title":"plot data","text":"","category":"section"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"(Image: image)","category":"page"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"One can right click at the blank region to select plots to show.","category":"page"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"(Image: image)","category":"page"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"The data used to plot includes four dimensions X Y Z W. X Y Z is regular dimensions and W is used to be calculated with others. To plot a heatmap, a matrix is necessay but the stored data format is as a vector so that it has to be specified the dimensions of the Z plotting matrix and reverse it in dimension 1 or 2. At the bottom region, one can do some simple data processing, and the selected data have bind to variables x, ys, z, ws. For Y and W dimension, they relate to variables ys and ws respectively and can be accessed by index. For convenience, ys[1] and ws[1] is simply y and w.","category":"page"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"One can middle click or right click at the plot region to find more options.","category":"page"},{"location":"Workflow/#Data-Reviewing","page":"Workflow","title":"Data Reviewing","text":"","category":"section"},{"location":"Workflow/","page":"Workflow","title":"Workflow","text":"Click on \"文件 -> \"打开文件\"(\"打开文件夹\") to open saved files. Here One can review the content stored in the file includes the states of instruments, the script, the circuit, the data and the plots. Right click on the tabbar \"绘图\" can modify the plots.","category":"page"},{"location":"","page":"Home","title":"Home","text":"CurrentModule = QInsControl","category":"page"},{"location":"#QInsControl","page":"Home","title":"QInsControl","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"QInsControl is designed for controling instruments and data aquiring, which is based on the nivisa and provides a  user-friendly GUI and a flexible script written mannar to keep both the convenience and universality.","category":"page"},{"location":"#install","page":"Home","title":"install","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"julia> ]\njulia> add ImPlot#main\njulia> add https://github.com/FaresX/QInsControl.jl.git","category":"page"},{"location":"#usage","page":"Home","title":"usage","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"using QInsControl\nQInsControl.start()","category":"page"},{"location":"New Instrument/#Instrument-register","page":"New Instrument","title":"Instrument register","text":"","category":"section"},{"location":"New Instrument/","page":"New Instrument","title":"New Instrument","text":"Instrument register provides a convenient mannar to add new instruments and define new quantities to extend the functionality. (Image: image)","category":"page"},{"location":"New Instrument/#Add-a-new-instrument","page":"New Instrument","title":"Add a new instrument","text":"","category":"section"},{"location":"New Instrument/","page":"New Instrument","title":"New Instrument","text":"It is very easy to add a new instrument by clicking on the button \"新建\". A well-defined instrument includes an icon,  an identification string, command type, input and output interface corresponding to the physical ones and several user-defined quantities. These attributes can be devided into two parts basic one and quantities which are described as follows.","category":"page"},{"location":"New Instrument/#Basic-Configuration","page":"New Instrument","title":"Basic Configuration","text":"","category":"section"},{"location":"New Instrument/","page":"New Instrument","title":"New Instrument","text":"icon : click on the button labeled an icon to change to a new one.","category":"page"},{"location":"New Instrument/","page":"New Instrument","title":"New Instrument","text":"识别字符 : identification string has to be unique for the editing instrument, which can be obtained by querying the instrument the command \"*IDN?\" and pick up the unique parts.","category":"page"},{"location":"New Instrument/","page":"New Instrument","title":"New Instrument","text":"命令类型 : command type as a hint for auto-generate set and get function can be made sure by looking up the instrument manual. At present, it surpports tsp (2600 series and so on) and scpi (mostly used). For the other command types, select the blank option.","category":"page"},{"location":"New Instrument/","page":"New Instrument","title":"New Instrument","text":"接口 : to add some input and output ports","category":"page"},{"location":"New Instrument/#Quantity","page":"New Instrument","title":"Quantity","text":"","category":"section"},{"location":"New Instrument/","page":"New Instrument","title":"New Instrument","text":"变量名 : variable name used internally which is better to consist only of English letters.","category":"page"},{"location":"New Instrument/","page":"New Instrument","title":"New Instrument","text":"启用 : a checkbox to decide whether the quantity is to be used","category":"page"},{"location":"New Instrument/","page":"New Instrument","title":"New Instrument","text":"别称 : name for convenient identification which is visible to user","category":"page"},{"location":"New Instrument/","page":"New Instrument","title":"New Instrument","text":"单位类型 : unit type of the obtained data via the specified quantity. When the data are text type, select the blank option.","category":"page"},{"location":"New Instrument/","page":"New Instrument","title":"New Instrument","text":"命令 : the command header for the specified quantity. For scpi, it has to be in the form Header Value for a sweepable or settable quantity or the form Header? for an only readable quantity. The button inssetget.jl on the right is used to open the file inssetget.jl to manually add functions of set and get which is necessary when command or command type is not in the standard form. When manually add the set and get functions, one have to ebey the following forms","category":"page"},{"location":"New Instrument/","page":"New Instrument","title":"New Instrument","text":"function [Instrument Name]_[Quantity Name]_set(instr, val)\nend\nfunction [Instrument Name]_[Quantity Name]_get(instr)\n    return readvalue\nend","category":"page"},{"location":"New Instrument/","page":"New Instrument","title":"New Instrument","text":"where instr parameter is necessary and generally used with fundamental functions write, query and read same as in NI VISA. Click on the rightmost button to hot reload all the functions.","category":"page"},{"location":"New Instrument/","page":"New Instrument","title":"New Instrument","text":"可选值 : This is only suitable for a settable quantity whose settable values are descrete. One can give a key on the left for convenience and corresponds to an available option value.","category":"page"},{"location":"New Instrument/","page":"New Instrument","title":"New Instrument","text":"变量类型 : It has three options sweep, set and read. Different type has different behavior.","category":"page"}]
}
