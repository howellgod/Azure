# Azure Deployment Plan

> **Status:** Executing

Generated: 2026-03-27 America/New_York

---

## 1. Project Overview

**Goal:** Create the Phase 1 repository, SQL schema scripts, Terraform infrastructure, and ADF scaffolding needed to move Power BI from direct Excel consumption to Azure SQL backed by Azure Data Factory.

**Path:** New Project

---

## 2. Requirements

| Attribute | Value |
|-----------|-------|
| Classification | Production |
| Scale | Medium |
| Budget | Balanced |
| **Subscription** | Existing Azure subscription hosting the current SQL database |
| **Location** | Existing Azure SQL region plus colocated new resources |

---

## 3. Components Detected

| Component | Type | Technology | Path |
|-----------|------|------------|------|
| Infrastructure | IaC | Terraform | `terraform/` |
| Database schema | Database | Azure SQL / T-SQL | `sql/` |
| Orchestration | Data integration | Azure Data Factory JSON | `adf/` |
| Documentation | Project docs | Markdown | `docs/` |

---

## 4. Recipe Selection

**Selected:** Terraform

**Rationale:** The user explicitly requested Terraform for Azure resource deployment, and the repo is focused on infrastructure plus database artifacts rather than an application runtime that benefits from `azd`.

---

## 5. Architecture

**Stack:** Managed data platform with existing Azure SQL plus Azure Data Factory orchestration

### Service Mapping

| Component | Azure Service | SKU |
|-----------|---------------|-----|
| Reporting database | Existing Azure SQL Database | Existing |
| Ingestion orchestration | Azure Data Factory | Managed service |
| Secrets | Azure Key Vault | Standard |

### Supporting Services

| Service | Purpose |
|---------|---------|
| Existing Azure SQL | Persist workbook-derived reporting data |
| Key Vault | Optional secret storage for connectors |
| Managed Identity | Data Factory access to Azure resources |
| Azure Monitor diagnostics | Optional baseline observability for new resources |

---

## 6. Execution Checklist

### Phase 1: Planning
- [x] Analyze workspace
- [x] Gather requirements
- [x] Confirm deployment style and existing SQL assumptions
- [x] Scan sample workbook and PBIX inputs
- [x] Select recipe
- [x] Plan architecture
- [x] User approved this plan

### Phase 2: Execution
- [x] Research components and repo structure
- [x] Generate infrastructure files
- [x] Generate SQL schema and view scripts
- [x] Generate ADF scaffolding
- [ ] Run full Azure validation workflow
- [ ] Update status to `Ready for Validation`

### Phase 3: Validation
- [ ] Invoke azure-validate skill
- [ ] All validation checks pass
- [ ] Update plan status to `Validated`
- [ ] Record validation proof below

### Phase 4: Deployment
- [ ] Provision new Azure resources
- [ ] Apply SQL scripts to the existing Azure SQL database
- [ ] Publish ADF artifacts
- [ ] Update plan status to `Deployed`

---

## 7. Validation Proof

| Check | Command Run | Result | Timestamp |
|-------|-------------|--------|-----------|
| Pending | Pending | Pending | Pending |

**Validated by:** Pending
**Validation timestamp:** Pending

---

## 8. Files to Generate

| File | Purpose | Status |
|------|---------|--------|
| `.azure/plan.md` | Source-of-truth Azure plan | Complete |
| `terraform/*.tf` | Terraform for new Azure resources | Complete |
| `sql/*.sql` | Azure SQL schema and reporting views | Complete |
| `adf/**/*.json` | ADF linked services, datasets, and pipeline scaffolding | Complete |
| `docs/*.md` | Workbook and model notes | Complete |

---

## 9. Next Steps

> Current: Execution

1. Run local validation for Terraform formatting and syntax.
2. Review and tune the Power BI compatibility view logic against live workbook outputs.
3. Create or connect the remote GitHub repository and push the initial commit.
4. Run the Azure validation workflow before deployment.
