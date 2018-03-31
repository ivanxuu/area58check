defmodule Area58check.Decoder do
  @moduledoc false
  # This module allows to decode a base58check binary to a map which
  # tells if it's correct.

  alias Area58check.{Crypto, Base58symbolChart, Prefixes}

  @doc """
  Decode a base58check binary to a map which tells if it's correct, and
  the type of string comparing the prefix to the already known prefixes.

  ## Examples:

      iex> {:ok, %{decoded: decoded}} = decode_string("5HpneLQNKrcznVCQpzodYwAmZ4AoHeyjuRf9iAHAa498rP5kuWb")
      {:ok, %Area58check{
        encoded: "5HpneLQNKrcznVCQpzodYwAmZ4AoHeyjuRf9iAHAa498rP5kuWb",
        decoded: <<1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239, 1, 35, 69, 103, 137, 171, 205, 239>>,
        version_bin: <<128>>,
        version: :wif
      }}
      iex> _privkey = decoded |> Base.encode16()
      "0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF"

  It checks the checksum to verify if correct.

      iex> decode_string("")
      {:error, :checksum_incorrect}
      iex> decode_string("5HpneLQNKrcznVCQpzodYwAmZ4AoHeyjuRf9iAHAa498rP5kuWc")
      {:error, :checksum_incorrect}

  Check if alphabet is correct. `O` is not a valid base58 character.

      iex> decode_string("Ol")
      {:error, :incorrect_base58}
  """
  @spec decode_string(String.t) :: {:ok, Area58check.t} | {:error, atom}
  def decode_string(string) do
    string # "1zhML"
    |>Base58symbolChart.check_valid_base58_chars() #=> "1zhML" or {:error, :incorrect_base58}
    |>decode_raw_string() #=> [0, 57, 40, 20, 19] or {:error, reason}
    |>verify_checksum() #=> %{:ok, %{decoded: <<..>>} or {:error, reason}
    |>extract_version() #=> %{:ok, %{decoded: <<..>>, ver...} or {:error, reason}
    |>merge_encoded(string) #=> %{:ok, %Area58check{encoded: ..., decoded: <<..>>, ver...} or {:error, reason}
  end

  #── PRIVATE ──────────────────────────────────────────────────────────
  # Merge the current result with the original encoded string
  defp merge_encoded({:ok, result}, encoded_str) do
    {:ok, Map.merge(%Area58check{encoded: encoded_str}, result)}
  end
  defp merge_encoded({:error, reason}, _string), do: {:error, reason}

  # if string starts with "1", it means that the real decoded value is
  # 0. We need to convert it separatelly or otherwise it will be lost by
  # the `Integer.undigits/2` function
  # Ex: decode_raw_string("1zhML")
  defp decode_raw_string("1"<>rest) do
    [Base58symbolChart.ascii_to_base58_char("1") | decode_raw_string(rest)]
  end
  # Ex: decode_raw_string("zhML")
  defp decode_raw_string(vers_payload_checksum) when is_binary(vers_payload_checksum) do
    vers_payload_checksum # => "zhML"
    # Convert back to integers in base58 from base58 characters
    |>Base58symbolChart.ascii_to_base58() #=> [57, 40, 20, 19]
    # Convert to a big endian number
    |>Integer.undigits(58) # 11_257_123
    # Convert that number to a list of base 256 (binary)
    |>Integer.digits(256) # [171, 197, 35]
  end
  # If there was an error previously just bubble up to the next piped
  # function
  defp decode_raw_string({:error, reason}), do: {:error,reason}

  # If there was an error previously just pass it to the next piped
  # function
  defp verify_checksum({:error, map}) do
    {:error, map}
  end
  # Ex: verify_checksum([0, 57, 40, 20, 19])
  defp verify_checksum(vers_payload_checksum) do
    # Split the version and payload from the checksum
    {vers_payload, checksum} =
      vers_payload_checksum
      |>Enum.split(-4) #=> {[4,16,47,...], [43,52,29,34]}
    # Calculate checksum and compare with provided to verify is correct
    if Crypto.checksum(:binary.list_to_bin(vers_payload)) === :binary.list_to_bin(checksum) do
      {:ok, vers_payload} #=> {:ok, [4,16,47,...]}
    else
      {:error, :checksum_incorrect}
    end
  end

  # From the binary which contains the version and the payload, try to
  # extract the version
  #Ex: extract_version({:ok, [0, 57, 40, 20, 19]})
  defp extract_version({:ok, vers_payload}) do
    vers_payload #=> [0, 57, 40, 20, 19]
    |>:binary.list_to_bin() #=> <<0, 57, 40, 20, 19>>
    |>Prefixes.get_version() #=> {:ok, %{decoded: ..., version: :p2pkh, ...}}
  end
  defp extract_version({:error, reason}), do: {:error, reason}

end
