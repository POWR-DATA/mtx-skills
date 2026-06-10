I'm loading Natural Earth data into PostGIS to support a geospatial feature. I need to:
- Query Natural Earth 110m for world countries and US states
- Understand if the 110m dataset covers all countries or just the US
- Join with WideWorldImporters sample database for city/state data
- Use geography casting for distance calculations
- Handle the warnings I'm seeing in DBeaver
- Update SQL Server container scripts that use `sqlcmd` after moving to SQL Server 2025 images
- Retrieve SQL Server and PostGIS geometry columns safely in Python (`pyodbc` and `psycopg2`)

I'm also seeing orange parser warnings on SQL Server `.STDistance()` and `.STContains()` calls — are these real errors or just DBeaver being overly cautious?
