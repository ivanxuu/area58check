defmodule Area58check.Prefixes do
  @moduledoc false
  # Tools to find out the version of an encoded string or to know the
  # binary which represents the version the user want to use.



  # complete list from:
  # https://en.bitcoin.it/wiki/List_of_address_prefixes
  @version_prefixes %{
    #atom                     binary                 hex        Example use                                     prec.sym  Example when processed by base58check
    #--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    p2pkh:                    <<0>>,	              # 0x00	      Pubkey hash (P2PKH address)	                    1	        17VZNX1SN5NtKa8UQFxwQbFeFc3iqRYhem
    p2sh:                     <<5>>,                # 0x05	      Script hash (P2SH address)	                    3	        3EktnHQD7RiAE6uzMj2ZifT9YgRrkSgzQX
    wif:                      <<128>>,              # 0x80	      Private key (WIF, un/compressed pubkey)	        5, K or L	L1aW4aubDFB7yfras2S1mN3bqg9nwySY8nkoLmJebSLD5BWv3ENZ
    bip32_pubkey:             <<4, 136, 178, 30>>,  # 0x0488B21E	HD Wallet, BIP32 pubkey	                        xpub	    xpub661MyMwAqRbcEYS8w7XLSVeEsBXy79zSzH1J8vCdxAZningWLdN3...
    bip32_privkey:            <<4, 136, 173, 228>>, # 0x0488ADE4	HD Wallet, BIP32 private key	                  xprv	    xprv9s21ZrQH143K24Mfq5zL5MhWK9hUhhGbd45hLXo2Pq2oqzMMo63o...
    tesnet_p2pkh:             <<111>>,              # 0x6F	      Testnet pubkey hash	                            m or n	  mipcBbFg9gMiCh81Kj8tqqdgoZub1ZJRfn
    tesnet_p2sh:              <<196>>,              # 0xC4	      Testnet script hash	                            2	        2MzQwSSnBHWHqSAqtTVQ6v47XtaisrJa1Vc
    tesnet_wif:               <<239>>,              # 0xEF	      Testnet Private key (WIF, un/compressed pubkey)	c or 9    cNJFgo1driFnPcBdBX8BrJrpxchBWXwXCvNH5SoSkdcF6JXXwHMm
    tesnet_bip32_pubkey:      <<4, 53, 135, 207>>,  # 0x043587CF	Testnet HD Wallet, BIP32 pubkey	                tpub	    tpubD6NzVbkrYhZ4WLczPJWReQycCJdd6YVWXubbVUFnJ5KgU5MDQrD9...
    tesnet_bip32_privkey:     <<4, 53, 131, 148>>,  # 0x04358394	Testnet HD Wallet, BIP32 private key	          tprv	    tprv8ZgxMBicQKsPcsbCVeqqF1KVdH7gwDJbxbzpCxDUsoXHdb6SnTPY...
  }
  # Show as a list like :bip32_privkey, :bip32_pubkey, :p2pkh, :p2sh...
  @prefixes_list @version_prefixes |> Map.keys() |> Enum.map(&(inspect(&1))) |> Enum.join(", ")

  @prefix_versions @version_prefixes |> Enum.map(fn({k,v})-> {v,k} end)
  @prefix_versions_map @prefix_versions |> Enum.into(%{})

  @doc """
  Returns the type of a prefix as a tuple, where the first item is the
  atom version (Ex: `bip32_privkey`) and the second is the binary prefix
  (Ex: `<<4, 136, 178, 30>>`)

  The argument has to be any of:
    - An atom. Ex: `:testnet_p2sh`
    - The hexadecimal or numeric representation. Ex: `0x043587CF`
    - Character list: Ex: `[4, 136, 178, 30]`
    - Binary string: Ex: `<<4, 136, 178, 30>>`

  There are several prefixes of any base58check encoded string. To make
  it easier for the developer to obtain the binary to know the version
  use this function.

  ## Examples

      iex> get_binary_version(:bip32_pubkey)
      {:bip32_pubkey, <<4, 136, 178, 30>>}
      iex> get_binary_version(0x0488B21E)
      {:bip32_pubkey, <<4, 136, 178, 30>>}
      iex> get_binary_version([4, 136, 178, 30])
      {:bip32_pubkey, <<4, 136, 178, 30>>}
      iex> get_binary_version(<<4, 136, 178, 30>>)
      {:bip32_pubkey, <<4, 136, 178, 30>>}
      iex> get_binary_version(:unknown_jkhfldksajf)
      ** (ArgumentError) :unknown_jkhfldksajf is not a recognized version. You can either pass a charlist (ex: [4, 136, 178, 30]), number (ex: 70617039), hexadecimal (ex: 0x043587CF), binary version (ex: <<4, 136, 178, 30>>), or a recognized atom like any of: :bip32_privkey, :bip32_pubkey, :p2pkh, :p2sh, :tesnet_bip32_privkey, :tesnet_bip32_pubkey, :tesnet_p2pkh, :tesnet_p2sh, :tesnet_wif, :wif

  I can use one I just made up. But I won't get recognized, so there
  won't be any atom telling the type.

      iex> get_binary_version(<<1, 2, 3, 4>>)
      {nil, <<1, 2, 3, 4>>}
  """
  # Ex: get_binary_version(:bip32_privkey)
  def get_binary_version(atom) when is_atom(atom) do
    case @version_prefixes[atom] do
      nil ->
        raise ArgumentError, message: "#{inspect atom} is not a " <>
          "recognized version. You can either pass a charlist "<>
          "(ex: [4, 136, 178, 30]), number (ex: 70617039), "<>
          "hexadecimal (ex: 0x043587CF), binary version "<>
          "(ex: <<4, 136, 178, 30>>), or a recognized atom "<>
          "like any of: #{@prefixes_list}"
      bin_version when is_binary(bin_version) -> {atom, bin_version}
    end
  end
  # Ex: get_binary_version(0x043587CF)
  def get_binary_version(num) when is_number(num) do
    num
    |>Integer.digits(256) #=> [4, 136, 178, 30]
    |>get_binary_version()
  end
  # Ex: get_binary_version([4, 136, 178, 30])
  def get_binary_version(dec) when is_list(dec) do
    dec
    |>:binary.list_to_bin() #=> <<4, 136, 178, 30>>
    |>get_binary_version()
  end
  # Ex: get_binary_version(<<4, 136, 178, 30>>)
  def get_binary_version(bin) when is_binary(bin) do
    {@prefix_versions_map[bin], bin} #=> {:bip32_privkey, <<4, 136, 178, 30>>}
  end

  @doc """
  Try to find out the version of an encoded base58 string using the
  prefix. Returns the string without the removed prefix, and two
  versions of the prefix, an atom with the string type (Ex: `:p2pkh`)
  and the binary of that prefix (ex: `<<0>>`)

  ## Examples

    iex> get_version(<<0, 1, 2, 3, 4, 5, 6>>)
    {:ok, %{
      decoded: <<1, 2, 3, 4, 5, 6>>,
      version_bin: <<0>>,
      version: :p2pkh}}
    iex> get_version(<<4, 53, 135, 207, 3, 4, 5, 6>>)
    {:ok, %{
      decoded: <<3, 4, 5, 6>>,
      version_bin: <<4, 53, 135, 207>>,
      version: :tesnet_bip32_pubkey}}

  If the version prefix can't be recognized:

    iex> get_version(<<9, 1, 2, 3, 4, 5, 6>>)
    {:ok, %{
      decoded: <<9, 1, 2, 3, 4, 5, 6>>,
      version_bin: <<>>,
      version: nil}}

  """
  def get_version(bin) when is_binary(bin) do
    _get_version(bin, @prefix_versions)
  end

  #── PRIVATE ──────────────────────────────────────────────────────────

  # Ex: _get_version("", [...])
  defp _get_version("", _versions) do
    {:ok, %{decoded: "", version_bin: nil, version: nil}}
  end
  # Try to match every known version
  # Ex: _get_version(<<0,1,2>>, [{<<0>>, :p2pkh} | {.., ..}])
  #     {:ok, %{decoded: <<1, 2>>, version_bin: <<0>>, version: :p2pkh }}
  defp _get_version(ver_payload, [{ver_bin, ver_atom}|other_versions]) do
    prefix_length = byte_size(ver_bin)
    case ver_payload do
      <<^ver_bin::binary-size(prefix_length), payload::binary>> ->
        {:ok, %{decoded: payload, version_bin: ver_bin, version: ver_atom }}
      ver_payload -> _get_version(ver_payload, other_versions)
    end
  end
  # If doesn't recognize the version...
  # Ex: _get_version("", [])
  defp _get_version(ver_payload, []) do
    {:ok, %{decoded: ver_payload, version_bin: <<>>, version: nil}}
  end
end
