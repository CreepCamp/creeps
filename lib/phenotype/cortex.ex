defmodule Phenotype.Cortex do 
	
  # Few things to concidere here. 
  # Cortex starts and wait end of execution. To do so, it has a count of run to.
  # But also a list of expected actuator responses. 
  # Once all actuators have answered, it will either start again, or notify 
  # exoself that it has finished.
  defstruct   id: nil, sensor_pids: [], actuator_pids: [], neuron_pids: [], exoself_pid: nil, run_left: 0, expected_actuators: []

	use GenServer

	def start_link(exoself_pid, id) do 
		GenServer.start_link(__MODULE__, [exoself_pid, id], [name: String.to_atom("#{__MODULE__}_#{id}")])
	end

	def init([exoself_pid, id] = opts) do 
		IO.puts "Initilizing #{__MODULE__}"
		
		ExoSelf.init_cortex(exoself_pid, self(), id)
		{:ok, %Phenotype.Cortex{exoself_pid: exoself_pid}}
	end	

  # AKA loop/2 by the book. This function init the cortex, ensuring it's got appropriate data.
	def update(pid, cortex, sensor_pids, neuron_pids ,actuator_pids) do 
		GenServer.cast(pid, {:update, cortex,sensor_pids, neuron_pids ,actuator_pids})
	end

  # This function is an extension to what loop/2 receive, it properly start the process.
  # Nb run is temporary, it'll be replaced by other means later on.
  def start(pid, nb_run) do  
    GenServer.cast(pid, {:start, nb_run})
  end

  def actuator_finished(pid, actuator_pid, data) do 
    GenServer.cast(pid, {:actuator_finished, actuator_pid, data})
  end

  def terminate(pid) do 
    GenServer.cast(pid, :terminate)
  end

  def handle_cast(:terminate, state) do
    IO.puts "#{__MODULE__} Imposed termination"
    {:stop, :normal, state}
  end

  def handle_cast({:actuator_finished, actuator_pid, _data}, state) do 
    expected_apids = List.delete(state.expected_actuators, actuator_pid) 

    if length(expected_apids) == 0 do
      # we don't expect anymore info from actuators, thus, turn has ended, do some magic
      # restart the process with one less run.
      IO.puts "End of Loop yeah"
      start(self(), state.run_left-1)
      {:noreply, %Phenotype.Cortex{state| expected_actuators: state.actuator_pids}}
    else 
      {:noreply, %Phenotype.Cortex{state| expected_actuators: expected_apids}}
    end  
  end

	def handle_cast({:update, cortex, sensor_pids, neuron_pids, actuator_pids}, state) do
		{:noreply, %Phenotype.Cortex{state| id: cortex.id, sensor_pids: sensor_pids, neuron_pids: neuron_pids, actuator_pids: actuator_pids, expected_actuators: actuator_pids}}
	end

  # Oddly enough, that's end condition. No more run, notify ExoSelf end of game.
  def handle_cast({:start, 0}, state) do 
    IO.puts "End of Game FYeah"
    ExoSelf.finished(state.exoself_pid, state.neuron_pids)
    {:noreply, %Phenotype.Cortex{state | run_left: 0, expected_actuators: state.actuator_pids}}
  end

  def handle_cast({:start, nb_run}, state) do 
    IO.puts "Begining of NN job ! #{nb_run} to go !"
    for spid <- state.sensor_pids do
      # Tell sensor to do the job.
      Phenotype.Sensor.sense(spid)
    end
    {:noreply, %Phenotype.Cortex{state | run_left: nb_run, expected_actuators: state.actuator_pids}}
  end
end
