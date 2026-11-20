// 5.2
int[] ProductExceptSelf(int[] nums)
{
  int prefix = 1;
  int n = nums.Length;

  var result = new int[nums.Length];

  for (int i = 0; i < n; i++)
  {
    result[i] = prefix;
    prefix *= nums[i];
  }

  int suffix = 1;

  for (int i = n - 1; i >= 0; i--)
  {
    result[i] *= suffix;
    suffix *= nums[i];
  }

  return result;
}
// 5.1

// int[] ProductExceptSelf(int[] nums)
// {
//     int n = nums.Length;

//     int[] prefix = new int[n];
//     int[] suffix = new int[n];
//     int[] result = new int[n];

//     prefix[0] = 1;
//     suffix[n - 1] = 1;

//     for (int i = 1; i < n; i++)
//     {
//         prefix[i] = prefix[i - 1] * nums[i - 1];
//     }

//     for (int i = n - 2; i >= 0; i--)
//     {
//         suffix[i] = suffix[i + 1] * nums[i + 1];
//     }

//     for (int i = 0; i < n; i++)
//     {
//         result[i] = prefix[i] * suffix[i];
//     }

//     return result;
// }

var result = ProductExceptSelf(new int[] { 1, 2, 3, 4 });

foreach (var item in result)
{
    Console.WriteLine(item);
}