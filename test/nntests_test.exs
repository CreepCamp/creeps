defmodule NntestsTest do
  use ExUnit.Case

  test "Basic neural network runs and kicks ass" do
    Genotype.clean(:ffnn)
    Genotype.construct()
    {:ok, expid} = ExoSelf.start_link(%{filename: :ffnn, pid: self() })
    assert_receive { :finished, ^expid }, 10_000
    # expect exo self to send a finished message within 10s.
  end
end
