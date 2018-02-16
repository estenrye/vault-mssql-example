FROM microsoft/aspnetcore-build:2.0.5-2.1.4-jessie as build
LABEL build="vault"
WORKDIR /app
COPY api.csproj .
RUN dotnet restore
COPY . .
RUN dotnet publish -c Release -o /out

FROM microsoft/aspnetcore:2.0.5-jessie
LABEL build="vault"
WORKDIR /app
COPY --from=build /out .

ENTRYPOINT [ "dotnet", "run", "api.dll" ]
