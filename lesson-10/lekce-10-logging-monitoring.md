# Lekce 10 – Logging a monitoring
## DevOps kurz - Infrastructure as Code, CI/CD, AWS

---

## Slide 1: Úvod do lekce
### Co se dnes naučíme

- **APM monitoring** – systémové vs. UX metriky
- **Monitoring infrastruktury** – co a jak sledovat
- **Logování** – best practices a nástroje
- **Alerting** – efektivní upozorňování
- **Support, SLA a falešná KPI** – co měřit správně
- **Praktický úkol** – implementace do pipeline

---

## Slide 2: Proč je monitoring kritický?
### Realita produkčních systémů

- **99.9% uptime** = 8.77 hodin výpadku ročně
- **Průměrná cena výpadku**: $5,600 za minutu
- **MTTR** (Mean Time To Recovery) je klíčová metrika
- **Proaktivní vs. reaktivní** přístup

> "You can't improve what you don't measure" - Peter Drucker

---

## Slide 3: APM - Application Performance Monitoring
### Co je APM?

**Application Performance Monitoring** = komplexní sledování výkonu aplikací

**Klíčové komponenty:**
- **Real User Monitoring (RUM)** - skuteční uživatelé
- **Synthetic Monitoring** - simulované testy
- **Application Topology** - mapa závislostí
- **Code-level diagnostics** - profiling kódu

---

## Slide 4: Systémové metriky vs. UX metriky
### Dva pohledy na výkon

| **Systémové metriky** | **UX metriky** |
|----------------------|----------------|
| CPU utilization (%) | Page Load Time |
| Memory usage (MB) | Time to First Byte |
| Disk I/O (IOPS) | Core Web Vitals |
| Network latency (ms) | Error Rate (%) |
| Response time (ms) | User Satisfaction |

**Klíčové pozorování:** Nízké systémové metriky ≠ dobrá UX

---

## Slide 5: Core Web Vitals - UX metriky
### Google's UX metriky

**LCP (Largest Contentful Paint)**
- Čas načtení hlavního obsahu
- Cíl: < 2.5s

**FID (First Input Delay)**
- Doba odezvy na první interakci
- Cíl: < 100ms

**CLS (Cumulative Layout Shift)**
- Stabilita layoutu během načítání
- Cíl: < 0.1

---

## Slide 6: Monitoring infrastruktury - Co sledovat?
### The Four Golden Signals (Google SRE)

1. **Latency** - doba odezvy požadavků
2. **Traffic** - množství požadavků
3. **Errors** - míra chybovosti
4. **Saturation** - využití zdrojů

**+ RED Method:**
- **Rate** - požadavky za sekundu
- **Errors** - chybovost
- **Duration** - doba trvání

---

## Slide 7: AWS CloudWatch - Základní monitoring
### Nativní AWS monitoring řešení

**Základní metriky (zdarma):**
- EC2: CPU, Network, Disk
- RDS: Connections, CPU, Memory
- Lambda: Invocations, Duration, Errors

**Detailed monitoring (placené):**
- 1-minutové intervaly
- Custom metriky
- Enhanced monitoring pro RDS

```bash
aws cloudwatch put-metric-data \
  --namespace "MyApp/Performance" \
  --metric-data MetricName=ResponseTime,Value=150,Unit=Milliseconds
```

---

## Slide 8: Logování - Best Practices
### Structured Logging

**Špatně:**
```
User login failed for john@example.com at 2024-01-15 10:30:45
```

**Správně (JSON):**
```json
{
  "timestamp": "2024-01-15T10:30:45Z",
  "level": "ERROR",
  "event": "user_login_failed",
  "user_email": "john@example.com",
  "ip_address": "192.168.1.100",
  "user_agent": "Mozilla/5.0...",
  "trace_id": "abc123def456"
}
```

---

## Slide 9: Log Levels a kdy je použít
### Hierarchie důležitosti

| Level | Kdy použít | Příklad |
|-------|------------|---------|
| **FATAL** | Aplikace se ukončuje | Database connection failed |
| **ERROR** | Chyba, ale aplikace pokračuje | User authentication failed |
| **WARN** | Potenciální problém | Deprecated API usage |
| **INFO** | Důležité události | User logged in |
| **DEBUG** | Detailní informace pro vývoj | SQL query executed |
| **TRACE** | Velmi detailní debugging | Function entry/exit |

---

## Slide 10: Centralizované logování - ELK Stack
### Elasticsearch, Logstash, Kibana

**Architektura:**
```
Application → Logstash → Elasticsearch → Kibana
     ↓
  Log Files
```

**AWS alternativa:**
```
Application → CloudWatch Logs → OpenSearch → Dashboards
```

**Výhody:**
- Centrální úložiště logů
- Pokročilé vyhledávání
- Vizualizace a dashboardy
- Alerting na základě logů

---

## Slide 11: Distributed Tracing
### Sledování požadavků napříč mikroslužbami

**Problém:** Jak sledovat požadavek přes 10 mikroslužeb?

**Řešení:** Distributed Tracing
- **Trace ID** - jedinečný identifikátor požadavku
- **Span ID** - identifikátor operace
- **Parent Span** - hierarchie volání

**Nástroje:**
- AWS X-Ray
- Jaeger
- Zipkin
- OpenTelemetry

---

## Slide 12: Alerting - Efektivní upozorňování
### Jak nastavit správné alerty

**Zásady dobrého alertingu:**
1. **Actionable** - lze něco udělat
2. **Relevant** - týká se vašeho týmu
3. **Timely** - včas, ale ne moc často
4. **Clear** - jasný popis problému

**Anti-patterns:**
- ❌ Alert fatigue (příliš mnoho alertů)
- ❌ Crying wolf (falešné poplachy)
- ❌ Vague alerts ("Something is wrong")

---

## Slide 13: SLA, SLO, SLI - Definice kvality
### Service Level Management

**SLI (Service Level Indicator)**
- Metrika kvality služby
- Příklad: 99.5% úspěšných požadavků

**SLO (Service Level Objective)**
- Cíl pro SLI
- Příklad: 99.9% dostupnost za měsíc

**SLA (Service Level Agreement)**
- Smlouva s penalizací
- Příklad: 99.9% dostupnost nebo refund

**Error Budget** = 100% - SLO (0.1% = 43 minut výpadku/měsíc)

---

## Slide 14: Falešná KPI a Vanity Metrics
### Co neměřit (nebo měřit opatrně)

**Vanity Metrics:**
- ❌ Počet deploymentů (bez kontextu kvality)
- ❌ Lines of Code (více ≠ lepší)
- ❌ 100% test coverage (bez kvality testů)
- ❌ Zero bugs (možná se netestuje dostatečně)

**Lepší metriky:**
- ✅ MTTR (Mean Time To Recovery)
- ✅ Change Failure Rate
- ✅ Lead Time for Changes
- ✅ Customer Satisfaction Score

---

## Slide 15: DORA Metrics - Měření DevOps výkonu
### Research-backed metriky

**4 klíčové DORA metriky:**

1. **Deployment Frequency**
   - Jak často nasazujeme do produkce

2. **Lead Time for Changes**
   - Čas od commitu po produkci

3. **Change Failure Rate**
   - % deploymentů způsobujících problémy

4. **Time to Restore Service**
   - Čas na obnovení po výpadku

---

## Slide 16: Monitoring as Code
### Infrastructure as Code pro monitoring

**Terraform příklad:**
```hcl
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}
```

---

## Slide 17: Observability vs. Monitoring
### Evoluce přístupu

**Monitoring (tradiční):**
- Známé problémy
- Předem definované metriky
- "Known unknowns"

**Observability (moderní):**
- Neznámé problémy
- Explorativní analýza
- "Unknown unknowns"

**3 pilíře Observability:**
1. **Metrics** - číselné hodnoty v čase
2. **Logs** - diskrétní události
3. **Traces** - požadavky napříč systémem

---

## Slide 18: Praktické nástroje a služby
### Ekosystém monitoring nástrojů

**Open Source:**
- Prometheus + Grafana
- ELK Stack (Elasticsearch, Logstash, Kibana)
- Jaeger (tracing)

**AWS Native:**
- CloudWatch (metriky, logy, alerty)
- X-Ray (distributed tracing)
- OpenSearch Service

**SaaS řešení:**
- Datadog, New Relic, Dynatrace
- Sentry (error tracking)
- PagerDuty (incident management)

---

## Slide 19: Domácí úkol - Implementace
### Přidání monitoring do CI/CD pipeline

**Úkoly:**
1. **Přidat logování** do aplikace (structured logs)
2. **Nastavit CloudWatch** metriky a alerty
3. **Implementovat health check** endpoint
4. **Vytvořit dashboard** s klíčovými metrikami
5. **Otestovat alert** - simulovat problém

**Deliverables:**
- Kód s logováním
- Terraform/CloudFormation pro monitoring
- Screenshot dashboardu
- Dokumentace alertů

---

## Slide 20: Shrnutí a další kroky
### Key Takeaways

✅ **Monitoring není jen o systémových metrikách**
✅ **UX metriky jsou stejně důležité**
✅ **Structured logging usnadňuje analýzu**
✅ **Alerty musí být actionable**
✅ **SLO/SLI pomáhají definovat kvalitu**
✅ **DORA metriky měří DevOps zralost**

**Další kroky:**
- Implementace observability do vašich projektů
- Nastavení SLO pro kritické služby
- Automatizace incident response

---

## Bonus Slide: Incident Response Playbook
### Když se něco pokazí

**1. Detect** (1-5 minut)
- Automatické alerty
- User reports

**2. Respond** (5-15 minut)
- Incident commander
- War room setup
- Initial assessment

**3. Mitigate** (15-60 minut)
- Rollback nebo hotfix
- Communication plan

**4. Resolve** (1-4 hodiny)
- Root cause analysis
- Post-mortem meeting
- Action items

**5. Learn** (1-2 týdny)
- Blameless post-mortem
- Process improvements
- Prevention measures
