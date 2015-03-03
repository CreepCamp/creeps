defmodule NntestsTest do
  use ExUnit.Case

  test "Basic neural network runs and kicks ass" do
    Genotype.clean(:ffnn)
    Genotype.construct()
    {:ok, expid} = ExoSelf.start_link(%{filename: :ffnn, pid: self() })
    assert_receive { :finished, ^expid }, 10_000
    # expect exo self to send a finished message within 10s.
  end

  test "Basic neural network should have a nice display :)" do
    File.rm("priv/dots/test_dot")
    File.rm("priv/dots/test_dot.png")
    Genotype.clean(:test_dot)
    Genotype.construct(:test_dot)
    Genotype.to_dot(:test_dot)
    assert_receive :finished, 10_000
    assert true = File.exists?("priv/dots/test_dot")
    assert true = File.exists?("priv/dots/test_dot.png")
  end
end
