using UbimiaAspTest.Services;

var builder = WebApplication.CreateBuilder(args);

// Servicios
builder.Services.AddRazorPages();
builder.Services.AddControllers();
builder.Services.AddScoped<CalculatorService>();

// Swagger (útil para demostrar el Web Service)
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new() { Title = "Ubimia Calculator API", Version = "v1" });
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseStaticFiles();
app.UseRouting();
app.UseAuthorization();

app.MapRazorPages();
app.MapControllers();

app.Run();
