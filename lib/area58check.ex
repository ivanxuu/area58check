defmodule Area58check do
  @moduledoc """
  This module includes the needed functions to encode or decode
  base58check strings.

  Base58check is used in Bitcoin whenever there is a need for a user to
  read or transcribe a number, such a bitcoin adresses, encrypted key,
  private key, or script hash.

  ## Prefixed versions
  The prefixed version parameter indicates what kind of binary is being
  encoded. E.g. If you are encoding a private key use `:wif`, if you are
  encoding a bitcoin address use `:p2pkh`. The version prefix will be
  embeded in the encoded version.
  You can also use other types described in `t:prefix_version_type/0`

  ## Checksum
  The encoded versions will include a few bytes to ensure that its
  correct and no transcribing errors were present.

  ## Usage

  To know the **decoded binary** of any encoded string just use the
  `encode/2` function indicating the prefix version you want:

      iex> privkey = "0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF" |> Base.decode16!()
      iex> %{decoded: _decoded} = encode(privkey, <<128>>)
      %Area58check{
        encoded: "5HpneLQNKrcznVCQpzodYwAmZ4AoHeyjuRf9iAHAa498rP5kuWb",
        decoded: <<1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239>>,
        version: :wif,
        version_bin: <<128>>
      }

  To know the **encoded string** of any binary use `decode/1` function:

      iex> {:ok, %{encoded: _encoded}} = decode("5HpneLQNKrcznVCQpzodYwAmZ4AoHeyjuRf9iAHAa498rP5kuWb")
      {:ok, %Area58check{
        encoded: "5HpneLQNKrcznVCQpzodYwAmZ4AoHeyjuRf9iAHAa498rP5kuWb",
        decoded: <<1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239>>,
        version: :wif,
        version_bin: <<128>>
      }}
  """
  alias __MODULE__.{Prefixes, Encoder, Decoder}

  @typedoc """
  Indicates the type of bitcoin string being encoded/decoded. E.g.: mainet
  WalletImportFormat (WIF), bitcoin address, testnet wif, etc.

  The prefixed version can be provided in several formats:

    - An atom. E.g.: `:testnet_p2sh`
    - The hexadecimal or numeric representation. E.g.: `0x043587CF`
    - Character list: E.g.: `[4, 136, 178, 30]`
    - Binary string: E.g.: `<<4, 136, 178, 30>>`
  """
  @type prefix_version_type :: atom | binary | pos_integer | nonempty_list(0..255)
  @typedoc """
  A result returned by both `encode/2` and `decode/1` with the prefixed
  version, the encoded base58check string, and the decoded binary.
  """
  @type t :: %Area58check{
    decoded: binary,
    encoded: String.t,
    version: atom,
    version_bin: binary}

  defstruct decoded: <<>>, encoded: "", version: nil, version_bin: <<>>

  @doc """
  Encodes a string using base58check with the provided version prefix .

  The argument `version_prefix` can be a binary, integer or a list of
  bytes (see examples next paragraph).
  All available prefixes are coded in the module `Area58check.Prefixes`.

  ## Examples

      iex> privkey = "0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF" |> Base.decode16!()
      iex> encode(privkey, :wif)
      %Area58check{
        encoded: "5HpneLQNKrcznVCQpzodYwAmZ4AoHeyjuRf9iAHAa498rP5kuWb",
        decoded: <<1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239>>,
        version: :wif,
        version_bin: <<128>>}

  The version prefix can be indicated in several alternative ways:

      iex> privkey = "0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF" |> Base.decode16!()
      iex> encode(privkey, <<128>>)
      %Area58check{
        encoded: "5HpneLQNKrcznVCQpzodYwAmZ4AoHeyjuRf9iAHAa498rP5kuWb",
        decoded: <<1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239>>,
        version: :wif,
        version_bin: <<128>>
      }
      iex> encode(privkey, 0x80)
      %Area58check{
        encoded: "5HpneLQNKrcznVCQpzodYwAmZ4AoHeyjuRf9iAHAa498rP5kuWb",
        decoded: <<1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239>>,
        version: :wif,
        version_bin: <<128>>
      }
      iex> encode(privkey, [128])
      %Area58check{
        encoded: "5HpneLQNKrcznVCQpzodYwAmZ4AoHeyjuRf9iAHAa498rP5kuWb",
        decoded: <<1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239>>,
        version: :wif,
        version_bin: <<128>>
      }

  Example to generate an uncompresed bitcoin address from public key

      iex> privkey = "0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF" |> Base.decode16!()
      iex> {uncompressed_pubkey, _priv_key} = :crypto.generate_key(:ecdh, :crypto.ec_curve(:secp256k1), privkey)
      iex> uncompressed_pubkey = :crypto.hash(:ripemd160, :crypto.hash(:sha256, uncompressed_pubkey))
      iex> encode(uncompressed_pubkey, <<0>>)
      %Area58check{
        encoded: "1CLrrRUwXswyF2EVAtuXyqdk4qb8DSUHCX",
        decoded: <<124, 106, 230, 190, 9, 150, 81, 133, 169, 75, 13, 161, 139, 201, 42, 157, 252, 238, 97, 23>>,
        version: :p2pkh,
        version_bin: <<0>>}

  If version is an atom, and is not recognized returns error:

      iex> encode("Any string", :sahdkjfhkjasdfhksldjf)
      ** (ArgumentError) Version prefix :sahdkjfhkjasdfhksldjf is not a recognized version. You can either pass a charlist (ex: [4, 136, 178, 30]), number (ex: 70617039), hexadecimal (ex: 0x043587CF), binary version (ex: <<4, 136, 178, 30>>), or a recognized atom like any of: :bip32_privkey, :bip32_pubkey, :p2pkh, :p2sh, :testnet_bip32_privkey, :testnet_bip32_pubkey, :testnet_p2pkh, :testnet_p2sh, :testnet_wif, :wif
  """
  @spec encode(String.t, prefix_version_type) :: t
  def encode(payload, version_prefix ) do
    # E.g.: get_binary_version(:pubkey_hash) # => {<<0>>}
    {version, version_bin} = Prefixes.get_binary_version( version_prefix )
    %Area58check{
      encoded: Encoder.encode_string(payload, version_bin),
      decoded: payload,
      version: version,
      version_bin: version_bin}
  end

  @doc """
  Decodes a previously encoded string using base58check returning the
  used version prefix, the original binary.

  An error message will be returned in case there was a checksum error
  or a character is not valid.

  ## Examples:

  Decode WIP key and get the hexadecimal private key

      iex> {:ok, %{decoded: decoded} } = decode("5HpneLQNKrcznVCQpzodYwAmZ4AoHeyjuRf9iAHAa498rP5kuWb")
      {:ok, %Area58check{
        encoded: "5HpneLQNKrcznVCQpzodYwAmZ4AoHeyjuRf9iAHAa498rP5kuWb",
        decoded: <<1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239>>,
        version: :wif,
        version_bin: <<128>>}}
      iex> decoded |> Base.encode16
      "0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF"

  If any character of the key is wrong (`J`), checksum will be invalid:

      iex> decode("5JpneLQNKrcznVCQpzodYwAmZ4AoHeyjuRf9iAHAa498rP5kuWb")
      {:error, :checksum_incorrect}

  The null string means the checksum is nor present, nor valid:

      iex> decode("")
      {:error, :checksum_incorrect}

  If any character is not a base58 character (E.g.: `0`)

      iex> decode("50pneLQNKrcznVCQpzodYwAmZ4AoHeyjuRf9iAHAa498rP5kuWb")
      {:error, :incorrect_base58}
  """
  @spec decode(String.t) :: {:ok, Area58check.t} | {:error, atom()}
  def decode(payload) do
    Decoder.decode_string(payload)
  end

end
