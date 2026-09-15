#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "${SCRIPT_DIR}/../../apps/RcsApi" && pwd)"

if [ -f "${APP_DIR}/RcsApi.csproj" ]; then
  echo "Demo application already exists at ${APP_DIR}. Skipping creation."
  exit 0
fi

echo "Creating standard .NET Web API application..."
mkdir -p "${APP_DIR}"
cd "${APP_DIR}"

dotnet new webapi --no-https -n RcsApi -o .

# Inject a mock hardcoded credential into Program.cs to guarantee a Secrets/SAST finding demo
cat << 'EOF' > Program.cs
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

var startTime = DateTime.UtcNow;

if (app.Environment.IsDevelopment() || true)
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// INTENTIONAL SECURITY FINDING FOR POC DEMO: Hardcoded Secret
string AWS_DEMO_SECRET = "AKIAIOSFODNN7EXAMPLE_SECRET_KEY_DO_NOT_USE";

// Comprehensive Health Check Endpoint
app.MapGet("/health", () =>
{
    var process = System.Diagnostics.Process.GetCurrentProcess();
    
    var healthInfo = new
    {
        status = "Healthy",
        timestamp = DateTime.UtcNow,
        uptime = DateTime.UtcNow - startTime,
        environment = app.Environment.EnvironmentName,
        metrics = new
        {
            allocatedMemoryMb = Math.Round(GC.GetTotalMemory(forceFullCollection: false) / (1024.0 * 1024.0), 2),
            workingSetMb = Math.Round(process.WorkingSet64 / (1024.0 * 1024.0), 2),
            threadCount = process.Threads.Count
        }
    };

    return Results.Ok(healthInfo);
})
.WithName("GetHealth")
.WithOpenApi();

var summaries = new[] { "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching" };

app.MapGet("/weatherforecast", () =>
{
    var forecast = Enumerable.Range(1, 5).Select(index =>
        new WeatherForecast
        (
            DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
            Random.Shared.Next(-20, 55),
            summaries[Random.Shared.Next(summaries.Length)]
        ))
        .ToArray();
    return forecast;
})
.WithName("GetWeatherForecast")
.WithOpenApi();

app.Run();

record WeatherForecast(DateOnly Date, int TemperatureC, string Summary)
{
    public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
}
EOF

echo "App generation complete."