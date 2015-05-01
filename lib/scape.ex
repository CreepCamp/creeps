defmodule Scape do 
  defmodule XOR do 
    defmodule Morphology do
      def sensors do 
        [
          %Genotype.Sensor{id: Genotype.generate_id(), name: :xor, vector_length: 2, scape: {:private, Scape.XOR}}
        ]
      end

      def actuators do 
        [
          %Genotype.Actuator{id: Genotype.generate_id(), name: :xor, vector_length: 1, scape: {:private, Scape.XOR}}
        ]
      end
    end
    defmodule Simulation do 
      use GenServer

      def start_link(opts), do: GenServer.start_link(__MODULE__, opts, []) 
      def init(opts) do
        {:ok, %{}}
      end

      def handle_call({:sense, caller}, from, state) do 
        
        {:reply,0, from, state}
      end

      def handle_call({:act, caller}, from,  state) do 

        {:reply, 0, from, state}
      end
    end
  end


  #
  # A Scape expect a few things :
  # First of all a Morphology Module with sensors and actuators function
  # That outputs an array of sensors / actuators
  # a private scape will be generated per training sessions.
  # a public scape is expected to have a pid() function defined.
  # @TODO add a behaviour for morphology and Simulation
  #
  # Second, a Simulation which is a Server accepting 2 calls + terminate
  # :sense => :perceive, data
  # :act => :result, fitness, should_stop
  #

  defmodule Test do 
    defmodule Morphology do 
      def sensors do 
        [
          %Genotype.Sensor{id: Genotype.generate_id(), name: :rng, vector_length: 2, scape: {:private, Scape.Test}}
        ]
      end

      def actuators do 
        [
          %Genotype.Actuator{id: Genotype.generate_id(), name: :pts, vector_length: 1, scape: {:private, Scape.Test}}
        ]
      end
    end

    defmodule Simulation do 
      use GenServer

      def start_link(opts), do: GenServer.start_link(__MODULE__, opts, []) 
      def init(opts) do
        {:ok, %{}}
      end

      def handle_call(:sense, from, state) do 
        {:reply, {:perceive,rng(2)}, from, state}
      end

      def handle_call(:act, from, state) do 
        {:reply, {:result, 1,1}, from, state}
      end

      # Create a vector of given length with random number inside.
      def rng(vector_length) do
        rng(vector_length, [])
      end

      def rng(0, acc) do
        acc
      end
      
      def rng(v, acc) do
        rng(v-1, [:random.uniform() | acc])
      end
    end
  end
end
