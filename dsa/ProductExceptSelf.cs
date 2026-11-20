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

var result = ProductExceptSelf(new int[] { -1, 1, 0, -3, 3 });
foreach (var item in result)
{
    Console.WriteLine(item);
}
