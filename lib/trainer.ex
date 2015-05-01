defmodule Trainer do 
  use GenServer

  # Serves as trainer config options and state.
  # First 6 serves as indicator, when either reach it's limit, the training ends.

  defstruct  attempt_limit: 5,
             attempt: 0,
             eval_limit: :infinite,
             eval: 0,
             fitness_limit: :infinite,
             best_fitness: 0,
             cycles: 0,
             time: 0,
             hidden_layer_density: [1,3],
             name: :experiment,
             scape: nil

  def go(scape), do: go(scape, %Trainer{})
  def go(scape, %Trainer{} = options) do
    start_link([scape,%Trainer{options|scape: scape}]) 
  end

  defp start_link(options), do: GenServer.start_link(__MODULE__, options, [])
  def init([scape, options]) do 
    GenServer.cast(self(), :loop)
    {:ok, options}
  end

  # This needs to come first as elixir evaluate function in order of definition.
  # (also explains why functions with similar names have to be grouped)
  def handle_cast(:loop, %Trainer{eval: e, eval_limit: elim,
                                  attempt: a, attempt_limit: alim,
                                  best_fitness: b, fitness_limit: flim} = state)
                                when 
                                  e > elim or 
                                  a > alim or
                                  b > flim
                                do
    # We have reached end of training for either reason..
    # Display it to the world.

    IO.puts "Training finished for #{state.name}, fitness: #{state.best_fitness}, runs: #{state.eval}"
    Genotype.to_dot(state.name)
    {:noreply, state}
  end

  # We do the job guys :)
  def handle_cast(:loop, state) do 
    Genotype.construct(state.name, state.scape, state.hidden_layer_density)
    Exoself.start(state.name, self())
    {:noreply, state}
  end

  def handle_info({:finished,fitness, evals, cycle, time, exoself_pid}, state) do
    # update state
    best = state.best_fitness
    attempt = state.attempt
    if fitness > best do 
      best = fitness
      attempt = 1
      Genotype.rename(state.name, "#{state.name}_best")
    end
    nstate = %Trainer{state|  eval: state.eval + evals,
                              cycles: state.cycles + cycle,
                              time: state.time + time,
                              best_fitness: fitness,
                              attempt: attempt}
    GenServer.cast(self(), :loop)
    {:noreply, nstate}
  end

  
  

end
