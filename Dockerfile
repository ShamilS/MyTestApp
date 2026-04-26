# Build stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

COPY MyApp.slnx .
COPY MyApp.Api/MyApp.Api.csproj MyApp.Api/
COPY MyApp.Core/MyApp.Core.csproj MyApp.Core/
COPY MyApp.Tests/MyApp.Tests.csproj MyApp.Tests/

RUN dotnet restore MyApp.slnx

COPY . .
RUN dotnet build MyApp.slnx --no-restore --configuration Release
RUN dotnet publish MyApp.Api/MyApp.Api.csproj -c Release -o /app/publish --no-build

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "MyApp.Api.dll"]