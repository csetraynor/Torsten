open Core_kernel
open Frontend
open Frontend_utils

let%expect_test "indexed type checking" =
  {|
transformed data {
    int indices[3] = {1, 2, 3};
    matrix[3, 4] mat[5];
    print(mat[indices, :, indices][2,1,1]);
}
|}
  |> typed_ast_of_string_exn
  |> Fmt.strf "@[<v>%a@]" Pretty_printing.pp_program
  |> print_endline ;
  [%expect
    {|
    transformed data {
      int indices[3] = {1, 2, 3};
      matrix[3, 4] mat[5];
      print(mat[indices,  : , indices][2, 1, 1]);
    } |}]
