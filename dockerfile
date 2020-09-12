# .NET Core SDK
FROM mcr.microsoft.com/dotnet/core/sdk:3.1.402-alpine3.12 AS dotnetcore-sdk

WORKDIR /source

# Copy Projects
COPY source/Application/Architecture.Application.csproj ./Application/
COPY source/Database/Architecture.Database.csproj ./Database/
COPY source/Domain/Architecture.Domain.csproj ./Domain/
COPY source/Model/Architecture.Model.csproj ./Model/
COPY source/Web/Architecture.Web.csproj ./Web/

# .NET Core Restore
RUN dotnet restore ./Web/Architecture.Web.csproj

# Copy All Files
COPY source .

# .NET Core Build and Publish
FROM dotnetcore-sdk AS dotnetcore-build
RUN dotnet publish ./Web/Architecture.Web.csproj -c Release -o /publish

# Angular
FROM node:14.10.1-alpine3.12 AS angular-build
ARG ANGULAR_ENVIRONMENT
WORKDIR /frontend
ENV PATH /frontend/node_modules/.bin:$PATH
COPY source/Web/Frontend/package.json .
RUN npm run restore
COPY source/Web/Frontend .
RUN npm run $ANGULAR_ENVIRONMENT

# ASP.NET Core Runtime
FROM mcr.microsoft.com/dotnet/core/aspnet:3.1.8-alpine3.12 AS aspnetcore-runtime
RUN apk add --no-cache icu-libs
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false
WORKDIR /app
COPY --from=dotnetcore-build /publish .
COPY --from=angular-build /frontend/dist ./Frontend/dist
EXPOSE 80
EXPOSE 443
ENTRYPOINT ["dotnet", "Architecture.Web.dll"]
