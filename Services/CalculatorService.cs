namespace UbimiaAspTest.Services;

public class CalculatorService
{
    /// <summary>
    /// Calcula el factorial de un entero no negativo.
    /// </summary>
    /// <param name="n">Entero mayor o igual a 0</param>
    /// <returns>Factorial de <paramref name="n"/> como <see cref="long"/></returns>
    /// <exception cref="ArgumentOutOfRangeException">Se lanza si <paramref name="n"/> es menor que 0</exception>
    /// <exception cref="OverflowException">Se lanza si <paramref name="n"/> es mayor a 20 (posible overflow <see cref="long"/>)</exception>
    public long Factorial(int n)
    {
        if (n < 0)
            throw new ArgumentOutOfRangeException(nameof(n), "El valor no puede ser negativo");

        if (n > 20)
            throw new OverflowException("El valor no puede ser mayor a 20 overeflow tipo long");

        long result = 1;
        for (int i = 2; i <= n; i++)
            result *= i;

        return result;
    }

    /// <summary>
    /// Ordena un arreglo de exactamente 5 enteros en orden ascendente usando Bubble Sort.
    /// </summary>
    /// <param name="numbers">Arreglo que debe contener exactamente 5 enteros</param>
    /// <returns>Nuevo arreglo con los elementos ordenados de forma ascendente</returns>
    /// <exception cref="ArgumentException">Si el arreglo no contiene exactamente 5 elementos</exception>
    public int[] SortFive(int[] numbers)
    {
        if (numbers == null || numbers.Length != 5)
            throw new ArgumentException("El arreglo debe contener exactamente 5 enteros", nameof(numbers));

        int[] sorted = (int[])numbers.Clone();

        // Implementación de Bubble Sort (asc)
        for (int i = 0; i < sorted.Length - 1; i++)
        {
            for (int j = 0; j < sorted.Length - 1 - i; j++)
            {
                if (sorted[j] > sorted[j + 1])
                {
                    (sorted[j], sorted[j + 1]) = (sorted[j + 1], sorted[j]);
                }
            }
        }

        return sorted;
    }
}
