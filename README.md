# Area58check

## What is Area58?

Area58 is a library to encode and decode base58check. Base58check is
used in Bitcoin whenever there is a need for a user to read or
transcribe a number, such a bitcoin adresses, encrypted key, private
key, or script hash.

## What is NOT Area58?

This can't be used to generate bitcoin address from a private key. It's
only a base58check encoder/decoder. But it's easy to generate a bitcoin
address from the private key.

Example: If you want to generate a (uncompressed) bitcoin address using
this library you can...

    iex> privkey = "0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF" |> Base.decode16!()
    iex> {uncompressed_pubkey, _priv_key} = :crypto.generate_key(:ecdh, :crypto.ec_curve(:secp256k1), privkey)
    iex> uncompressed_pubkey = :crypto.hash(:ripemd160, :crypto.hash(:sha256, uncompressed_pubkey))
    iex> Area58check.encode(uncompressed_pubkey, <<0>>)
    %Area58check{
      encoded: "1CLrrRUwXswyF2EVAtuXyqdk4qb8DSUHCX",
      decoded: <<1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239>>,
      version: :p2pkh,
      version_bin: <<0>>}

or you can use another library that does all that for you.

## What is base58check?

#### Encoding
Base58 charset is based on easy to trancribe characters, upper and
lower case letters and numbers excluding `0`, `O`, `l`, `I`.

#### Bitcoin version prefixes
Usually there is a version (binary number) to signal what kind of string
is being encoded.
[list of bitcoin prefixes](https://en.bitcoin.it/wiki/List_of_address_prefixes)

Example: for standard bitcoin address, is used the hexadecimal
number 0x00, for compressed WIF (allows to import a private key in
bitcoin) is used 0x80, etc.

#### Checksum

When a string is encoded, 4 bytes (or 32bits), are added to the end by
`Area58check.encode` function as a checksum to make sure that no
characters were wrongly transcribed. This checksum is not meant to allow
to fix a wrong transcribed string, but it allows to verify if string is
correct or not.

## Usage

#### Encoding

Encode a private key into WIF (Wallet Import Format):

    iex> privkey = "0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF" |> Base.decode16!()
    iex> Area58check.encode(privkey, :wif)
    %Area58check{encoded: "5HpneLQNKrcznVCQpzodYwAmZ4AoHeyjuRf9iAHAa498rP5kuWb",
      decoded: <<1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239>>,
      version: :wif,
      version_bin: <<128>>}
    iex> Area58check.encode(privkey, [128])
    %Area58check{encoded: "5HpneLQNKrcznVCQpzodYwAmZ4AoHeyjuRf9iAHAa498rP5kuWb",
      decoded: <<1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239>>,
      version: :wif,
      version_bin: <<128>>}
    iex> Area58check.encode(privkey, <<128>>)
    %Area58check{encoded: "5HpneLQNKrcznVCQpzodYwAmZ4AoHeyjuRf9iAHAa498rP5kuWb",
      decoded: <<1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239>>,
      version: :wif,
      version_bin: <<128>>}
    iex> Area58check.encode(privkey, 0x80)
    %Area58check{encoded: "5HpneLQNKrcznVCQpzodYwAmZ4AoHeyjuRf9iAHAa498rP5kuWb",
      decoded: <<1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239>>,
      version: :wif,
      version_bin: <<128>>}

Encode a public key into an address:

    iex> {uncompressed_pubkey, _priv_key} = :crypto.generate_key(:ecdh, :crypto.ec_curve(:secp256k1), privkey)
    iex> derived_uncomp_pubkey = :crypto.hash(:ripemd160, :crypto.hash(:sha256, uncompressed_pubkey))
    iex> Area58check.encode(derived_uncomp_pubkey, 0x00)
    %Area58check{
      decoded: <<124, 106, 230, 190, 9, 150, 81, 133, 169, 75, 13, 161, 139, 201, 42, 157, 252, 238, 97, 23>>,
      encoded: "1CLrrRUwXswyF2EVAtuXyqdk4qb8DSUHCX",
      version: :p2pkh,
      version_bin: <<0>>}

Error when version is unknown:

    iex> Area58check.encode(privkey, :jhkdsfajhkfdasjhkfd)
    ** (ArgumentError) :jhkdsfajhkfdasjhkfd is not a recognized version.
    You can either pass a charlist (ex: [4, 136, 178, 30]), number (ex:
    70617039), hexadecimal (ex: 0x043587CF), binary version (ex: <<4,
    136, 178, 30>>), or a recognized atom like any of: :bip32_privkey,
    :bip32_pubkey, :p2pkh, :p2sh, :testnet_bip32_privkey,
    :testnet_bip32_pubkey, :testnet_p2pkh, :testnet_p2sh, :testnet_wif, :wif

#### Decoding

Decoding strings encoded with base58check:

    iex> Area58check.decode("1CLrrRUwXswyF2EVAtuXyqdk4qb8DSUHCX")
    {:ok, %Area58check{decoded: <<124, 106, 230, 190, 9, 150, 81, 133, 169, 75, 13, 161, 139, 201, 42, 157, 252, 238, 97, 23>>,
      encoded: "1CLrrRUwXswyF2EVAtuXyqdk4qb8DSUHCX",
      version: :p2pkh,
      version_bin: <<0>>}}
    iex> Area58check.decode("5HpneLQNKrcznVCQpzodYwAmZ4AoHeyjuRf9iAHAa498rP5kuWb")
    {:ok, %Area58check{
      decoded: <<1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239>>,
      encoded: "5HpneLQNKrcznVCQpzodYwAmZ4AoHeyjuRf9iAHAa498rP5kuWb",
      version: :wif,
      version_bin: <<128>>
    }}

If checksum is not valid returns error:

    iex> Area58check.decode("1CheckSumError")
    {:error, :checksum_incorrect}

If contains a non valid character like `0`, `O`, `l`, `I`, returns
error:

    iex> Area58check.decode("ContainsInvalidCharacter0")
    {:error, :incorrect_base58}

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `area58check` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:area58check, "~> 0.1"},
  ]
end
```

The docs can be found at
[https://hexdocs.pm/area58check](https://hexdocs.pm/area58check).

