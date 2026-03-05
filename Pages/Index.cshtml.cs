using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using UbimiaAspTest.Services;

namespace UbimiaAspTest.Pages;

public class IndexModel : PageModel
{
    private readonly CalculatorService _calculator;

    public IndexModel(CalculatorService calculator)
    {
        _calculator = calculator;
    }

    // --- Factorial ---
    [BindProperty]
    public int? FactorialInput { get; set; }
    public long? FactorialResult { get; set; }
    public string? FactorialError { get; set; }

    // --- Ordenamiento ---
    [BindProperty]
    public string? SortInput { get; set; }   // "3,1,4,1,5"
    public int[]? SortResult { get; set; }
    public int[]? SortOriginal { get; set; }
    public string? SortError { get; set; }

    public void OnGet() { }

    public IActionResult OnPostFactorial()
    {
        if (!FactorialInput.HasValue)
        {
            FactorialError = "Ingresá un número entero";
            return Page();
        }

        try
        {
            FactorialResult = _calculator.Factorial(FactorialInput.Value);
        }
        catch (ArgumentOutOfRangeException ex)
        {
            FactorialError = ex.Message;
        }
        catch (OverflowException ex)
        {
            FactorialError = ex.Message;
        }
        catch (Exception)
        {
            FactorialError = "Error inesperado al calcular el factorial";
        }

        return Page();
    }

    public IActionResult OnPostSort()
    {
        if (string.IsNullOrWhiteSpace(SortInput))
        {
            SortError = "Ingresá 5 números separados por coma";
            return Page();
        }

        try
        {
            int[] numbers = SortInput
                .Split(',', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries)
                .Select(s => int.Parse(s))
                .ToArray();

            SortOriginal = numbers;
            SortResult   = _calculator.SortFive(numbers);
        }
        catch (FormatException)
        {
            SortError = "Todos los valores deben ser números enteros";
        }
        catch (ArgumentException ex)
        {
            SortError = ex.Message;
        }
        catch (Exception)
        {
            SortError = "Error inesperado al ordenar los números";
        }

        return Page();
    }
}
