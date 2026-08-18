# Example Input

## Context

Northwind Analytics' marketing team wants a refreshable Excel workbook over their Supabase project: the `interest_signups` table and the `hits_daily` view, both readable by a `reporting` role that was just created. Two people (Sam and Priya) will refresh it; five others will only read it from the shared drive. The consultant also wants to script the pivot tables with PowerShell so the layout is reproducible.

## Input provided

**Database:** Supabase session pooler — host `aws-0-<region>.pooler.supabase.com`, port `5432`, database `postgres`, user `reporting.<project-ref>`, password held by the project owner

**Objects:** `public.interest_signups` (table, RLS on), `public.hits_daily` (view)

**Excel:** Microsoft 365 desktop for the refreshers; readers open the file from SharePoint

**Symptoms so far:**
- Installing the latest Npgsql from GitHub did nothing — Excel still says the PostgreSQL connector needs a driver
- After a manual connection, `interest_signups` reported "0 rows loaded"
- A PowerShell run that opened the workbook and built pivots left every query table showing "ExternalData_1: Getting Data..." and the pivots full of "(blank)"

**Ask:** the working driver, a shareable workbook, and a safe way to script the pivots.
