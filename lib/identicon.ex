defmodule Identicon do
  @moduledoc """
  Identicon generator
  """

  @doc """
  Pass a string input and get identicon generated in the local folder

  ## Examples

      iex> Identicon.main('my_name')
      :ok

  """
  def main(input) do
    input
    |> hash_input
    |> pick_color
    |> build_grid
    |> filter_odd_squares
    |> build_pixel_map
    |> draw_image
    |> save_image(input)
  end

  @doc """
  Generates hash from string input, converts to list and puts in the `Identicon.Image` struct

  ## Examples
        iex(1)> Identicon.hash_input('my_name')
        %Identicon.Image{
          color: nil,
          grid: nil,
          hex: [43, 48, 197, 6, 1, 8, 49, 7, 141, 253, 140, 92, 254, 26, 135, 212],
          pixel_map: nil
        }
  """

  def hash_input(input) do
    hex =
      :crypto.hash(:md5, input)
      |> :binary.bin_to_list()

    %Identicon.Image{hex: hex}
  end

  @doc """
  Picks first 3 values from `Identicon.Image`'s hex list and puts them in color as rgb

  ## Examples
        iex(1)> Identicon.pick_color(%Identicon.Image{
        ...>  color: nil,
        ...>  grid: nil,
        ...>  hex: [43, 48, 197, 6, 1, 8, 49, 7, 141, 253, 140, 92, 254, 26, 135, 212],
        ...>  pixel_map: nil
        ...>})
        %Identicon.Image{
          color: {43, 48, 197},
          grid: nil,
          hex: [43, 48, 197, 6, 1, 8, 49, 7, 141, 253, 140, 92, 254, 26, 135, 212],
          pixel_map: nil
        }
  """

  def pick_color(%Identicon.Image{hex: [r, g, b | _tail]} = image) do
    %Identicon.Image{image | color: {r, g, b}}
  end

  @doc """
  Build identicon grid and put it in the `Identicon.Image` struct.

  Identicon grid is a 5x5 grid
  Left and right columns are mirrored
  For example `[1][2][3][2][1]`

  So we chunk the hex list by 3. Then mirror the right side. See `Identicon.mirror_row/1`

  ## Examples
        iex> Identicon.build_grid(%Identicon.Image{ color: {43, 48, 197}, grid: nil, hex: [43, 48, 197, 6, 1, 8, 49, 7, 141, 253, 140, 92, 254, 26, 135, 212], pixel_map: nil})
        %Identicon.Image{
          color: {43, 48, 197},
          grid: [
            {43, 0},
            {48, 1},
            {197, 2},
            {48, 3},
            {43, 4},
            {6, 5},
            {1, 6},
            {8, 7},
            {1, 8},
            {6, 9},
            {49, 10},
            {7, 11},
            {141, 12},
            {7, 13},
            {49, 14},
            {253, 15},
            {140, 16},
            {92, 17},
            {140, 18},
            {253, 19},
            {254, 20},
            {26, 21},
            {135, 22},
            {26, 23},
            {254, 24}
          ],
          hex: [43, 48, 197, 6, 1, 8, 49, 7, 141, 253, 140, 92, 254, 26, 135, 212],
          pixel_map: nil
        }
  """

  def build_grid(%Identicon.Image{hex: hex} = image) do
    grid =
      hex
      |> Enum.chunk(3)
      |> Enum.map(&mirror_row/1)
      |> List.flatten()
      |> Enum.with_index()

    %Identicon.Image{image | grid: grid}
  end

  @doc """
  Mirrors the grid row

  ## Examples
        iex(25)> Identicon.mirror_row([43, 48, 197])
        [43, 48, 197, 48, 43]
  """

  def mirror_row(row) do
    [first, second | _tail] = row
    row ++ [second, first]
  end

  @doc """
  Filters odd squares from the `Identicon.Image` grid
  Only even squares are going to be colored in identicon grid.

  ## Examples
        iex> Identicon.filter_odd_squares(%Identicon.Image{
        ...>             color: {43, 48, 197},
        ...>             grid: [
        ...>               {43, 0},
        ...>               {48, 1},
        ...>               {197, 2},
        ...>               {48, 3},
        ...>               {43, 4},
        ...>               {6, 5},
        ...>               {1, 6},
        ...>               {8, 7},
        ...>               {1, 8},
        ...>               {6, 9},
        ...>               {49, 10},
        ...>               {7, 11},
        ...>               {141, 12},
        ...>               {7, 13},
        ...>               {49, 14},
        ...>               {253, 15},
        ...>               {140, 16},
        ...>               {92, 17},
        ...>               {140, 18},
        ...>               {253, 19},
        ...>               {254, 20},
        ...>               {26, 21},
        ...>               {135, 22},
        ...>               {26, 23},
        ...>               {254, 24}
        ...>             ],
        ...>             hex: [43, 48, 197, 6, 1, 8, 49, 7, 141, 253, 140, 92, 254, 26, 135, 212],
        ...>             pixel_map: nil
        ...>           })
        %Identicon.Image{
        color: {43, 48, 197},
        grid: [
          {48, 1},
          {48, 3},
          {6, 5},
          {8, 7},
          {6, 9},
          {140, 16},
          {92, 17},
          {140, 18},
          {254, 20},
          {26, 21},
          {26, 23},
          {254, 24}
        ],
        hex: [43, 48, 197, 6, 1, 8, 49, 7, 141, 253, 140, 92, 254, 26, 135, 212],
        pixel_map: nil
        }
  """

  def filter_odd_squares(%Identicon.Image{grid: grid} = image) do
    grid =
      Enum.filter(grid, fn {code, _index} ->
        rem(code, 2) == 0
      end)

    %Identicon.Image{image | grid: grid}
  end

  @doc """
  Builds pixel map for `:egd`

  ## Examples
        iex> Identicon.build_pixel_map(%Identicon.Image{
        ...>         color: {43, 48, 197},
        ...>         grid: [
        ...>           {48, 1},
        ...>           {48, 3},
        ...>           {6, 5},
        ...>           {8, 7},
        ...>           {6, 9},
        ...>           {140, 16},
        ...>           {92, 17},
        ...>           {140, 18},
        ...>           {254, 20},
        ...>           {26, 21},
        ...>           {26, 23},
        ...>           {254, 24}
        ...>         ],
        ...>         hex: [43, 48, 197, 6, 1, 8, 49, 7, 141, 253, 140, 92, 254, 26, 135, 212],
        ...>         pixel_map: nil
        ...>    })
        %Identicon.Image{
          color: {43, 48, 197},
          grid: [
            {48, 1},
            {48, 3},
            {6, 5},
            {8, 7},
            {6, 9},
            {140, 16},
            {92, 17},
            {140, 18},
            {254, 20},
            {26, 21},
            {26, 23},
            {254, 24}
          ],
          hex: [43, 48, 197, 6, 1, 8, 49, 7, 141, 253, 140, 92, 254, 26, 135, 212],
          pixel_map: [
            {{50, 0}, {100, 50}},
            {{150, 0}, {200, 50}},
            {{0, 50}, {50, 100}},
            {{100, 50}, {150, 100}},
            {{200, 50}, {250, 100}},
            {{50, 150}, {100, 200}},
            {{100, 150}, {150, 200}},
            {{150, 150}, {200, 200}},
            {{0, 200}, {50, 250}},
            {{50, 200}, {100, 250}},
            {{150, 200}, {200, 250}},
            {{200, 200}, {250, 250}}
          ]
        }
  """

  def build_pixel_map(%Identicon.Image{grid: grid} = image) do
    pixel_map =
      Enum.map(grid, fn {_code, index} ->
        horizontal = rem(index, 5) * 50
        vertical = div(index, 5) * 50

        top_left = {horizontal, vertical}
        bottom_right = {horizontal + 50, vertical + 50}

        {top_left, bottom_right}
      end)

    %Identicon.Image{image | pixel_map: pixel_map}
  end

  @doc """
  Renders `:egd` image.
  """

  def draw_image(%Identicon.Image{color: color, pixel_map: pixel_map}) do
    image = :egd.create(250, 250)
    fill = :egd.color(color)

    Enum.each(pixel_map, fn {start, stop} ->
      :egd.filledRectangle(image, start, stop, fill)
    end)

    :egd.render(image)
  end

  @doc """
  Saves `:egd` image to a file named as the initial input of `Identicon.main/1`
  """

  def save_image(image, input) do
    File.write("#{input}.png", image)
  end
end
