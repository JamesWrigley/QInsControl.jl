"""
    Controller(instrnm, addr)

construct a Controller to send commands to the instrument determined by (instrnm, addr). A Controller has three ways to
send commands to the Processor: wirte read query.
```julia
julia> ct(write, cpu, "*IDN?", Val(:write))
"done"

julia> ct(read, cpu, Val(:read))
"read"

julia> ct(query, cpu, "*IDN?", Val(:query))
"query"
```

the commands needed to execute is not necessary to be wirte, read or query.

```julia
julia> idn_get(instr) = query(instr, "*IDN?")
idn_get (generic function with 1 method)

julia> ct(idn_get, cpu, Val(:read))
"query"
```
the definition of function idn_get must happen before the Controller ct is logged in or one can log out and log in again.
"""
struct Controller
    id::UUID
    instrnm::String
    addr::String
    lock::ReentrantLock
    databuf::Dict{UUID,String}
    Controller(instrnm, addr) = new(uuid4(), instrnm, addr, ReentrantLock(), Dict())
end
function Base.show(io::IO, ct::Controller)
    str = """
            id : $(ct.id)
       instrnm : $(ct.instrnm)
       address : $(ct.addr)
        buffer : $(ct.databuf)
    """
    print(io, str)
end

"""
    Processor()

construct a Processor to deal with the commands sended into by Controllers.
"""
struct Processor
    id::UUID
    controllers::Dict{UUID,Controller}
    cmdchannel::Channel{Tuple{UUID,UUID,Function,String,Val}}
    exechannels::Dict{String,Channel{Tuple{UUID,UUID,Function,String,Val}}}
    tasks::Dict{String,Task}
    taskhandlers::Dict{String,Bool}
    resourcemanager::Ref{UInt32}
    instrs::Dict{String,Instrument}
    running::Ref{Bool}
    fast::Ref{Bool}
    Processor() = new(
        uuid4(), Dict(), Channel{Tuple{UUID,UUID,Function,String,Val}}(64),
        Dict(), Dict(), Dict(), 0, Dict(), false, false
    )
end
function Base.show(io::IO, cpu::Processor)
    str1 = """
                id : $(cpu.id)
           running : $(cpu.running[])
              mode : $(cpu.fast[] ? "fast" : "slow")
   ResourceManager : $(cpu.resourcemanager[])
       controllers :
    """
    print(io, str1)
    for ct in values(cpu.controllers)
        print(io, "\t\t\tController\n")
        ct_strs = split(string(ct), '\n')[1:end-1]
        print(io, string(join(fill("\t\t", 4) .* ct_strs, "\n"), "\n\n"))
    end
    str2 = """
              tasks : 
    """
    print(io, str2)
    for (addr, state) in cpu.taskhandlers
        l = length(addr)
        if l < 26
            print(io, string(" "^(26 - length(addr)), addr, " : ", state))
        else
            print(io, string(addr, " : ", state))
        end
    end
end

"""
    find_resources(cpu::Processor)

auto-detect available instruments.
"""
find_resources(cpu::Processor) = Instruments.find_resources(cpu.resourcemanager[])

"""
    login!(cpu::Processor, ct::Controller)

log the Controller in the Processor which can be done before and after the cpu started.
"""
function login!(cpu::Processor, ct::Controller)
    push!(cpu.controllers, ct.id => ct)
    if cpu.running[]
        # @warn "cpu($(cpu.id)) is running!"
        if !haskey(cpu.instrs, ct.addr)
            push!(cpu.instrs, ct.addr => instrument(ct.instrnm, ct.addr))
            push!(cpu.exechannels, ct.addr => Channel{Tuple{UUID,UUID,Function,String,Val}}(64))
            push!(cpu.taskhandlers, ct.addr => true)
            t = Threads.@spawn :interactive while cpu.taskhandlers[ct.addr]
                isready(cpu.exechannels[ct.addr]) && runcmd(cpu, take!(cpu.exechannels[ct.addr])...)
                cpu.fast[] || sleep(0.001)
                yield()
            end
            # @info "task(address: $(ct.addr)) is created"
            push!(cpu.tasks, ct.addr => errormonitor(t))
            connect!(cpu.resourcemanager[], cpu.instrs[ct.addr])
        end
    else
        haskey(cpu.instrs, ct.addr) || push!(cpu.instrs, ct.addr => instrument(ct.instrnm, ct.addr))
    end
    return nothing
end

"""
    logout!(cpu::Processor, ct::Controller)

log the Controller out the Processor.

    logout!(cpu::Processor, addr::String)

log all the Controllers that control the instrument with address addr out the Processor.
"""
function logout!(cpu::Processor, ct::Controller)
    popct = pop!(cpu.controllers, ct.id, 1)
    popct == 1 && return nothing
    if !in(popct.addr, map(ct -> ct.addr, values(cpu.controllers)))
        popinstr = pop!(cpu.instrs, ct.addr)
        if cpu.running[]
            # @warn "cpu($(cpu.id)) is running!"
            cpu.taskhandlers[popinstr.addr] = false
            try
                wait(cpu.tasks[popinstr.addr])
            catch e
                @error "an error occurs during logging out" exception = e
            end
            pop!(cpu.taskhandlers, popinstr.addr)
            pop!(cpu.tasks, popinstr.addr)
            pop!(cpu.exechannels, popinstr.addr)
            disconnect!(popinstr)
        end
    end
    return nothing
end
function logout!(cpu::Processor, addr::String)
    for ct in values(cpu.controllers)
        ct.addr == addr && logout!(cpu, ct)
    end
end

function (ct::Controller)(f::Function, cpu::Processor, val::String, ::Val{:write})
    @assert haskey(cpu.controllers, ct.id) "Controller is not logged in"
    @assert cpu.running[] "processor has not been started"
    cmdid = uuid4()
    put!(cpu.cmdchannel, (ct.id, cmdid, f, val, Val(:write)))
    t1 = time()
    while !haskey(ct.databuf, cmdid) && time() - t1 < 6
        cpu.fast[] || sleep(0.001)
        yield()
    end
    @assert haskey(ct.databuf, cmdid) "timeout"
    lock(ct.lock) do
        pop!(ct.databuf, cmdid)
    end
end
function (ct::Controller)(f::Function, cpu::Processor, ::Val{:read})
    @assert haskey(cpu.controllers, ct.id) "Controller is not logged in"
    @assert cpu.running[] "processor has not been started"
    cmdid = uuid4()
    put!(cpu.cmdchannel, (ct.id, cmdid, f, "", Val(:read)))
    t1 = time()
    while !haskey(ct.databuf, cmdid) && time() - t1 < 6
        cpu.fast[] || sleep(0.001)
        yield()
    end
    @assert haskey(ct.databuf, cmdid) "timeout"
    lock(ct.lock) do
        pop!(ct.databuf, cmdid)
    end
end
function (ct::Controller)(f::Function, cpu::Processor, val::String, ::Val{:query})
    @assert haskey(cpu.controllers, ct.id) "Controller is not logged in"
    @assert cpu.running[] "processor has not been started"
    cmdid = uuid4()
    put!(cpu.cmdchannel, (ct.id, cmdid, f, val, Val(:query)))
    t1 = time()
    while !haskey(ct.databuf, cmdid) && time() - t1 < 6
        cpu.fast[] || sleep(0.001)
        yield()
    end
    @assert haskey(ct.databuf, cmdid) "timeout"
    lock(ct.lock) do
        pop!(ct.databuf, cmdid)
    end
end

function runcmd(cpu::Processor, ctid::UUID, cmdid::UUID, f::Function, val::String, ::Val{:write})
    ct = cpu.controllers[ctid]
    @eval $f($(cpu.instrs[ct.addr]), $val)
    lock(ct.lock) do
        push!(ct.databuf, cmdid => "done")
    end
    return nothing
end
function runcmd(cpu::Processor, ctid::UUID, cmdid::UUID, f::Function, ::String, ::Val{:read})
    ct = cpu.controllers[ctid]
    lock(ct.lock) do
        push!(ct.databuf, cmdid => @eval $f($(cpu.instrs[ct.addr])))
    end
    return nothing
end
function runcmd(cpu::Processor, ctid::UUID, cmdid::UUID, f::Function, val::String, ::Val{:query})
    ct = cpu.controllers[ctid]
    lock(ct.lock) do
        push!(ct.databuf, cmdid => @eval $f($(cpu.instrs[ct.addr]), $val))
    end
    return nothing
end

function init!(cpu::Processor)
    if !cpu.running[]
        cpu.fast[] = false
        # empty!(cpu.cmdchannel)
        while isready(cpu.cmdchannel)
            take!(cpu.cmdchannel)
        end
        empty!(cpu.exechannels)
        empty!(cpu.tasks)
        empty!(cpu.taskhandlers)
        cpu.resourcemanager[] = ResourceManager()
        for (addr, instr) in cpu.instrs
            try
                connect!(cpu.resourcemanager[], instr)
            catch e
                @error "connecting to $addr failed" exception = e
            end
            push!(cpu.exechannels, addr => Channel{Tuple{UUID,UUID,Function,String,Val}}(64))
            push!(cpu.taskhandlers, addr => false)
        end
        cpu.running[] = false
    end
    return nothing
end

function run!(cpu::Processor)
    if !cpu.running[]
        cpu.running[] = true
        errormonitor(
            Threads.@spawn :interactive while cpu.running[]
                if isready(cpu.cmdchannel)
                    ctid, cmdid, f, val, type = take!(cpu.cmdchannel)
                    put!(cpu.exechannels[cpu.controllers[ctid].addr], (ctid, cmdid, f, val, type))
                end
                cpu.fast[] || sleep(0.001)
                yield()
            end
        )
        for (addr, exec) in cpu.exechannels
            cpu.taskhandlers[addr] = true
            t = Threads.@spawn :interactive while cpu.taskhandlers[addr]
                isready(exec) && runcmd(cpu, take!(exec)...)
                cpu.fast[] || sleep(0.001)
                yield()
            end
            @info "task(address: $addr) is created"
            push!(cpu.tasks, addr => errormonitor(t))
        end
        errormonitor(
            @async while cpu.running[]
                for (addr, t) in cpu.tasks
                    if istaskfailed(t)
                        @warn "task(address: $addr) is failed, recreating..."
                        newt = Threads.@spawn :interactive while cpu.taskhandlers[addr]
                            isready(cpu.exechannels[addr]) && runcmd(cpu, take!(cpu.exechannels[addr])...)
                            cpu.fast[] || sleep(0.001)
                            yield()
                        end
                        @info "task(address: $addr) is recreated"
                        push!(cpu.tasks, addr => errormonitor(newt))
                    end
                end
                cpu.fast[] || sleep(0.001)
                yield()
            end
        )
    end
    return nothing
end

"""
    stop!(cpu::Processor)

stop the Processor.
"""
function stop!(cpu::Processor)
    if cpu.running[]
        cpu.running[] = false
        cpu.fast[] = false
        for addr in keys(cpu.taskhandlers)
            cpu.taskhandlers[addr] = false
        end
        for t in values(cpu.tasks)
            try
                wait(t)
            catch e
                @error "an error occurs during stopping Processor:\n$cpu" exception = e
            end
        end
        for instr in values(cpu.instrs)
            disconnect!(instr)
        end
        empty!(cpu.controllers)
        while isready(cpu.cmdchannel)
            take!(cpu.cmdchannel)
        end
        empty!(cpu.exechannels)
        empty!(cpu.taskhandlers)
        empty!(cpu.tasks)
        empty!(cpu.instrs)
    end
    return nothing
end

"""
    start!(cpu::Processor)

start the Processor.
"""
start!(cpu::Processor) = (init!(cpu); run!(cpu))

"""
    reconnect!(cpu::Processor)

reconnect the instruments that log in the Processor.
"""
reconnect!(cpu::Processor) = connect!.(cpu.resourcemanager[], values(cpu.instrs))

"""
    slow!(cpu::Processor)

change the cpu mode to slow mode. Default mode is slow mode, which decrease the cpu cost.
"""
slow!(cpu::Processor) = cpu.fast[] = false

"""
    fast!(cpu::Processor)

change the cpu mode to fast mode. Default mode is slow mode. The fast mode is not necessary in most cases.
"""
fast!(cpu::Processor) = cpu.fast[] = true