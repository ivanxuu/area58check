defmodule Area58check.Base58symbolChart do
  @moduledoc false
  # Module which allows to map a number between 0 to 57 (58 different
  # characters) to the base58check alphabet.

  # This is the valid alpahbet for base58
  @charset '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'

  # Create symbol chart like: %{ 0  => "1", ..., 9  =>  "A", 10 => "B", 11 => "C", ... }
  # To convert from ascii to base58
  @ascii_chart @charset |> Enum.with_index |> Enum.into(%{})
  # To convert from base58 to ascii
  @base58_chart @ascii_chart |> Enum.map(fn {k,v} -> {v,k} end) |> Enum.into(%{})

  @doc """
  Convert each number of a list to a character of the base58 according
  the base58 character table.

  ## Examples:

  Converting a list of several characters:

    iex> base58_to_ascii([0])
    "1"  # Which internally is <<49>>
    iex> base58_to_ascii([0,1,2,3,57])
    "1234z" # Which internally is <<49, 50, 51, 52, 122>>

  Will output error if one number is not less than 58:

    iex> base58_to_ascii([0,1,2,3,58])
    ** (ArgumentError) You tried to convert `58` to base58 but is not a number < 58, or a list of numbers where each < 58
  """
  @spec base58_to_ascii([0..57]) :: binary()
  # Ex: ascii_to_base58([]) #=> ""
  def base58_to_ascii([]), do: ""
  # Ex: ascii_to_base58([0,1,2,3,57]) #=> "123z"
  def base58_to_ascii([char|rest]) do
    base58_to_ascii_char(char) <> base58_to_ascii(rest)
  end

  @doc """
  Similar to `base58_to_ascii/1` but its only meant for a single
  character.

  ## Examples:
    iex> base58_to_ascii_char(0)
    "1"
    iex> base58_to_ascii_char(57)
    "z"

  Will output error if one number is not less than 58:

    iex> base58_to_ascii_char(59)
    ** (ArgumentError) You tried to convert `59` to base58 but is not a number < 58, or a list of numbers where each < 58
  """
  @spec base58_to_ascii_char(0..57) :: <<_::8>>
  # Convert number to a character of the base58 according the
  # base58 character table.
  # Ex: ascii_to_base58(57) #=> "z"
  def base58_to_ascii_char(char) when is_integer(char) and char < 58 do
    <<@base58_chart[char]>>
  end
  def base58_to_ascii_char(not_char) do
    raise ArgumentError, message: "You tried to convert "<>
      "`#{not_char}` to base58 but is not a number < 58, "<>
      "or a list of numbers where each < 58"
  end

  @doc """
  Convert each base58 character to a list of integers in base58.

  ## Examples:

  Converting a list of several characters:

    iex> ascii_to_base58("1") # "1" is <<49>>
    [0]
    iex> ascii_to_base58("1234z") # "1234z" is <<49, 50, 51, 52, 122>>
    [0,1,2,3,57]

  Will output error if one character is not a base58 character from
  '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'

    iex> ascii_to_base58("123Ol")
    ** (ArgumentError) You tried to convert `O` from base58 but is not a valid character of base58. Valid characters are 123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz

  """
  @spec ascii_to_base58(binary()) :: [0..57]
  # Ex: ascii_to_base58("") #=> []
  def ascii_to_base58(""), do: []
  # Ex: ascii_to_base58("1234z") #=> [0,1,2,3,57]
  def ascii_to_base58(<<char, rest::binary>>) do
    [ascii_to_base58_char(<<char>>) | ascii_to_base58(rest)]
  end

  @doc """
  Similar to `ascii_to_base58/1` but only for converting one character.

  ## Examples:

  Converting only one character:

    iex> ascii_to_base58_char("1")
    0
    iex> ascii_to_base58_char("z")
    57

  If it has a non base58 character (Typically l,O,0):

    iex> ascii_to_base58("0")
    ** (ArgumentError) You tried to convert `0` from base58 but is not a valid character of base58. Valid characters are 123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz
  """
  @spec ascii_to_base58_char(binary()) :: 0..57
  def ascii_to_base58_char(<<char>>) do
    case @ascii_chart[char] do
      integer when integer < 58 -> integer
      nil ->
        raise ArgumentError, message: "You tried to convert "<>
          "`#{<<char>>}` from base58 but is not a valid character "<>
          "of base58. Valid characters are #{@charset}"
    end
  end

  @doc """
  Return a truthy value if the string in the parameter contain only
  characters of the base58alpabeth. If it contain any non valid
  parameter returns {:error, :incorrect_base58}

  ## Examples

  All characters are valid:

    iex> check_valid_base58_chars("abc1z")
    "abc1z"

  Character '0' is not allowed in base58:

    iex> check_valid_base58_chars("abc1z0")
    {:error, :incorrect_base58}

  """
  @spec check_valid_base58_chars(binary()) ::
     binary()| {:error, :incorrect_base58}
  def check_valid_base58_chars(string) when is_binary(string) do
    String.match?(string, ~r/^[#{@charset}]*$/)
    |>if(do: string, else: {:error, :incorrect_base58})
  end
end
