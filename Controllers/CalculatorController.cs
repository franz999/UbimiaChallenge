using Microsoft.AspNetCore.Mvc;
using UbimiaAspTest.Services;

namespace UbimiaAspTest.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CalculatorController : ControllerBase
{
    private readonly CalculatorService _calculator;

    public CalculatorController(CalculatorService calculator)
    {
        _calculator = calculator;
    }

    /// <summary>
    /// Calcula el factorial de n.
    /// GET /api/calculator/factorial/5
    /// </summary>
    [HttpGet("factorial/{n}")]
    public IActionResult Factorial(int n)
    {
        try
        {
            long result = _calculator.Factorial(n);
            return Ok(new { input = n, factorial = result });
        }
        catch (ArgumentOutOfRangeException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
        catch (OverflowException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { error = "Error interno del servidor", detail = ex.Message });
        }
    }

    /// <summary>
    /// Ordena 5 números enteros de menor a mayor.
    /// POST /api/calculator/sort
    /// Body: { "numbers": [3, 1, 4, 1, 5] }
    /// </summary>
    [HttpPost("sort")]
    public IActionResult Sort([FromBody] SortRequest request)
    {
        try
        {
            if (request?.Numbers == null)
                return BadRequest(new { error = "Debe enviar un arreglo de 5 números en el campo numbers" });

            int[] sorted = _calculator.SortFive(request.Numbers);
            return Ok(new { input = request.Numbers, sorted });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { error = "Error interno del servidor", detail = ex.Message });
        }
    }
}

public class SortRequest
{
    public int[] Numbers { get; set; } = Array.Empty<int>();
}
