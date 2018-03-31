defmodule Area58check.Encoder do
  @moduledoc false
  # This module allows to encode a binary to a base58check.

  alias Area58check.{Crypto, Base58symbolChart}

  @doc """
  Encode a binary into base58check with a version of the type of string
  being encoded adding a checksum.

  Arguments is a binary string of any size (normally a 64Bytes is used),
  plus the version also in binary.

  ## Examples

    iex> privkey = "0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF" |> Base.decode16!()
    iex> {uncompressed_pubkey, _priv_key} = :crypto.generate_key(:ecdh, :crypto.ec_curve(:secp256k1), privkey)
    iex> derived_uncomp_pubkey = :crypto.hash(:ripemd160, :crypto.hash(:sha256, uncompressed_pubkey))
    iex> encode_string(derived_uncomp_pubkey, <<0>>)
    "1CLrrRUwXswyF2EVAtuXyqdk4qb8DSUHCX"

  Encode null string:

    iex> encode_string("", <<0>>)
    "1Wh4bh"
  """
  @spec encode_string(binary, binary) :: String.t | no_return()
  def encode_string(payload, version_prefix) when is_binary(version_prefix) do
    # Concatenate the version with the string to be encoded
    versioned_payload = version_prefix <> payload # <<0>> <> <<1, 2, 3>>
    # Concatenate the (version+payload + checksum) together
    (versioned_payload <> Crypto.checksum(versioned_payload))
    |>encode_versioned_string()
  end
  def encode_string(_payload, _version_prefix) do
    raise ArgumentError, message: "First argument should be a binary"
  end

  #── PRIVATE ──────────────────────────────────────────────────────────

  # Encode string assuming that the version, payload and checksum are
  # concatenated together.

  # If string starts with zero, those will be lost if we don't convert
  # separately.
  # Ex: encode_versioned_string(<<0,1,2,3>>)
  defp encode_versioned_string(<<0, checksumed_payload::binary>> ) do
    Base58symbolChart.base58_to_ascii_char(0) <>
      encode_versioned_string(checksumed_payload)
  end
  # This asumes that `vers_payload_check` contains concatenated version_prefix <>
  # payload <> checksum. Payload should not contain any leading zeros or
  # they will be lost.
  # Ex: encode_versioned_string(<<1,2,3>>)
  defp encode_versioned_string(vers_checksumed_payload)
    when is_binary(vers_checksumed_payload) do
    vers_checksumed_payload #=> <<124, 106, 230, 190, 9, 150, 81, 133, 169, 75, 13, 161, 139, 201, 42, 157, 252, 238, 97, 23, 202, 56, 155, 228>>
    # Convert to integer as a single big-endian bignumber. Should not
    # contain any leading zeros, as they will discarded.
    |>:binary.decode_unsigned(:big) #=> 3050710266992610275399901494860636957854608474636618865636
    # Convert that number to a list of base 58 number. Change big
    # decimal number to base 58.
    |>Integer.digits(58) #=> [11, 19, 49, 49, 24, 27, 54, 30, 50, 54, 56, 14, 1, 13, 28, 9, 51, 52, 30, 56, 48, 36, 43, 3, 48, 34, 7, 12, 25, 27, 16, 11, 30]
    # Convert each byte of list to a byte of the base58 according the
    # base58 character table. Ex: '0' becomes '1', '25' becomes 'S'
    |>Base58symbolChart.base58_to_ascii() #=> "CLrrRUwXswyF2EVAtuXyqdk4qb8DSUHCX"
  end

end
