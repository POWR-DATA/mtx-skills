# Example Input — Time-Series Use Case Assessment

## Context

A manufacturing organisation wants to monitor energy consumption across their production facility to reduce costs, identify waste, and understand which production lines and shifts consume the most energy.

## Input provided

**Use case description:** Monitor electrical energy consumption across production lines in a manufacturing facility. Identify consumption patterns, anomalies, high-consumption periods, and opportunities to reduce energy costs.

**Assets and processes involved:** Five production lines (Line 1 through Line 5), electrical sub-metering panels at each line, and a facility-level main meter. A utilities building houses HVAC and compressed air systems that also have sub-meters.

**Source systems:** An industrial energy monitoring system connected to electrical sub-meters. Data is stored in a local historian. REST API access is available.

**Tag or signal list:**
- Active power (kW) per sub-meter — 12 meters in total
- Reactive power (kVAR) per sub-meter
- Facility-level total active power
- Production line status (running/idle/stopped) — from a separate SCADA system

**Sampling frequency:** Energy data: 1-minute intervals. SCADA status data: event-based (status changes only).

**History requirements:** 12 months minimum for trend and seasonal analysis. Ideally 24 months.

**Latency requirements:** Near-real-time not required for reporting. An hourly refresh for operational dashboards and a daily refresh for management reporting are sufficient.

**Target consumers:** Facility manager (operational dashboard), finance and operations team (monthly energy reporting), sustainability team (carbon reporting)

**Analytics needs:** Consumption by production line, shift, and time period. Anomaly detection for unusual consumption spikes. Benchmarking against production output (energy intensity).

**Known data quality issues:** Some sub-meters have had calibration issues and occasionally produce zero readings or negative values. SCADA status data has gaps when the system was offline for maintenance.
