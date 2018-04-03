defmodule Area58checkTest do
  use ExUnit.Case
  doctest Area58check, import: true

  describe "Encode and decode public key" do
    @pubkeyhash <<124, 106, 230, 190, 9, 150, 81, 133, 169, 75, 13, 161, 139, 201, 42, 157, 252, 238, 97, 23>>
    test "" do
      %{encoded: encoded} = Area58check.encode(@pubkeyhash, :p2pkh)
      {:ok, %{decoded: decoded}} = Area58check.decode(encoded)
      assert decoded === @pubkeyhash
    end
  end

  describe "Encode and decode a random binary" do
    # Generate a random binary of length ranging from 0 to 50 bytes.
    @random_bin :crypto.strong_rand_bytes(Enum.random(0..50))
    @version 0
    test "will be the same string" do
      %{encoded: encoded} = Area58check.encode(@random_bin, @version)
      {:ok, %{decoded: decoded}} = Area58check.decode(encoded)
      assert decoded === @random_bin
    end
  end

end
