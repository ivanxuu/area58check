defmodule Area58check.Crypto do
  @moduledoc false
  #Several crypto related functions in erlang and wrapped in elixir
  #functions.

  @doc """
  sha256 hash function.

  It always returns a binary of length 64 Bytes (or 256 bits).

  ## Examples:

  It works in any binary argument:

    iex> sha256("Any binary string")
    <<234, 79, 243, 250, 95, 195, 243, 27, 227, 50, 104, 90, 40, 117, 226, 203, 9, 226, 41, 30, 162, 39, 57, 180, 192, 110, 151, 230, 15, 185, 157, 229>>

  But it's mainly used when working with public keys:

    iex> privkey = "0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF" |> Base.decode16!()
    iex> {uncompressed_pubkey, _priv_key} = :crypto.generate_key(:ecdh, :crypto.ec_curve(:secp256k1), privkey)
    iex> _pubkey = ripemd160(sha256(uncompressed_pubkey))
    <<124, 106, 230, 190, 9, 150, 81, 133, 169, 75, 13, 161, 139, 201, 42, 157, 252, 238, 97, 23>>
  """
  @spec sha256(String.t) :: <<_::256>>
  def sha256(payload) do
    :crypto.hash(:sha256, payload)
  end

  @doc """
  ripemd160 hash function.

  It always returns a binary of length 160 bits (or 20 Bytes).

  ## Examples:

  It works in any binary argument:

    iex> ripemd160("Any binary string")
    <<151, 23, 122, 58, 30, 171, 33, 75, 84, 65, 91, 222, 73, 172, 26, 56, 95, 190, 26, 236>>

  But it's mainly used when working with public keys:

    iex> privkey = "0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF" |> Base.decode16!()
    iex> {uncompressed_pubkey, _priv_key} = :crypto.generate_key(:ecdh, :crypto.ec_curve(:secp256k1), privkey)
    iex> ripemd160(sha256(uncompressed_pubkey))
    <<124, 106, 230, 190, 9, 150, 81, 133, 169, 75, 13, 161, 139, 201, 42, 157, 252, 238, 97, 23>>
  """
  @spec ripemd160(String.t) :: <<_::160>>
  def ripemd160(payload) do
    :crypto.hash(:ripemd160, payload)
  end

  @doc """
  Base58check checksum used in base58check. It will be attached so we
  can later check if any of the characters of the payload has been
  altered.

  It always return 4 Bytes.

  The checksum in base58check is defined by:
    1. Compute 64 Bytes hash of the payload.
    2. Compute 64 Bytes hash of step 1.
    3. Take only the first 4 bytes of 2.

  ## Examples:

  It works in any binary argument:

    iex> checksum("Any binary string")
    <<129, 119, 29, 167>>

  Also works with charlist:

    iex> checksum(<<1,2,255>>) === checksum([1,2,255])
    true

  But it's mainly used with public or private keys:

    iex> privkey = "0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF" |> Base.decode16!()
    iex> version_prefix = <<0>>
    iex> checksum(version_prefix <> privkey)
    <<2, 252, 125, 189>>
  """
  @spec checksum(String.t | [byte]) :: <<_::64>>
  def checksum(payload) do
    payload
    |>sha256() # Return a 64 Bytes hash
    |>sha256() # Return a second 64 Bytes re-hash
    |>Kernel.binary_part(0, 4) # Take only first 4 bytes
  end

end
