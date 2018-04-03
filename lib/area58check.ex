defmodule Area58check do
  @moduledoc """

  """
  alias __MODULE__.{Prefixes, Encoder, Decoder}

  @type base58version :: atom | binary  | pos_integer | nonempty_list(0..255)
  @type t :: %Area58check{decoded: binary,
    encoded: String.t,
    version: atom,
    version_bin: binary}

  defstruct decoded: <<>>, encoded: "", version: nil, version_bin: <<>>

  @default_options []

  @doc """
  ## Examples

      iex> privkey = "0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF" |> Base.decode16!()
      iex> encode(privkey, version: :wif)
      %Area58check{
        encoded: "5HpneLQNKrcznVCQpzodYwAmZ4AoHeyjuRf9iAHAa498rP5kuWb",
        decoded: <<1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239>>,
        version: :wif,
        version_bin: <<128>>}

  The version can be indicated in several alternative ways:

      iex> privkey = "0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF" |> Base.decode16!()
      iex> encode(privkey, version: <<128>>)
      %Area58check{
        encoded: "5HpneLQNKrcznVCQpzodYwAmZ4AoHeyjuRf9iAHAa498rP5kuWb",
        decoded: <<1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239>>,
        version: :wif,
        version_bin: <<128>>
      }
      iex> encode(privkey, version: 0x80)
      %Area58check{
        encoded: "5HpneLQNKrcznVCQpzodYwAmZ4AoHeyjuRf9iAHAa498rP5kuWb",
        decoded: <<1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239>>,
        version: :wif,
        version_bin: <<128>>
      }
      iex> encode(privkey, version: [128])
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
    iex> encode(uncompressed_pubkey, version: <<0>>)
    %Area58check{
      encoded: "1CLrrRUwXswyF2EVAtuXyqdk4qb8DSUHCX",
      decoded: <<124, 106, 230, 190, 9, 150, 81, 133, 169, 75, 13, 161, 139, 201, 42, 157, 252, 238, 97, 23>>,
      version: :p2pkh,
      version_bin: <<0>>}

  If version is an atom, and is not recognized returns error:

      iex> encode("Any string", version: :sahdkjfhkjasdfhksldjf)
      ** (ArgumentError) Version prefix :sahdkjfhkjasdfhksldjf is not a recognized version. You can either pass a charlist (ex: [4, 136, 178, 30]), number (ex: 70617039), hexadecimal (ex: 0x043587CF), binary version (ex: <<4, 136, 178, 30>>), or a recognized atom like any of: :bip32_privkey, :bip32_pubkey, :p2pkh, :p2sh, :tesnet_bip32_privkey, :tesnet_bip32_pubkey, :tesnet_p2pkh, :tesnet_p2sh, :tesnet_wif, :wif
  """
  @spec encode(String.t, [version: any] | [] ) :: t
  def encode(payload, options \\ []) do
    options = Keyword.merge(@default_options, options)
    # Ex: get_binary_version(:pubkey_hash) # => {<<0>>}
    {version, version_bin} = Prefixes.get_binary_version( options[:version] )
    %Area58check{
      encoded: Encoder.encode_string(payload, version_bin),
      decoded: payload,
      version: version,
      version_bin: version_bin}
  end

  @doc """
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

  If any character is not a base58 character (Ex: `0`)

     iex> decode("50pneLQNKrcznVCQpzodYwAmZ4AoHeyjuRf9iAHAa498rP5kuWb")
     {:error, :incorrect_base58}
  """
  @spec decode(String.t) :: {:ok, Area58check.t} | {:error, atom()}
  def decode(payload) do
    Decoder.decode_string(payload)
  end

end
