# Azure Landing Zone + Entra Lab

A minimal Azure landing zone written in Bicep, plus a step-by-step Microsoft Entra lab guide, with CMMC practice mappings. Built as a **lab for learning**, using a fictional tenant ("Talvex").

> **Lab, not production.** This is learning material. Do not deploy it to a production subscription or use it as-is for a real environment.
> **No CUI.** Nothing in this repo contains, or should be used with, Controlled Unclassified Information, real customer data, or real credentials.

## What it deploys

The Bicep template (`infra/main.bicep`, subscription scope) creates:

- **Policy guardrails**: built-in Azure Policy assignments: the NIST SP 800-171 Rev. 2 initiative (audit-oriented) and Allowed locations
- **Log Analytics workspace with a daily cap**: low retention and a daily ingestion cap to keep lab costs down
- **Budget alert**: a monthly budget with email notifications
- **Defender for Cloud plans set to Free**: no paid Defender plans are enabled
- A set of resource groups following a simple platform / corp / enclave layout

## Repo layout

```
infra/
  main.bicep               # subscription-scope template
  main.bicepparam          # UNTESTED STARTER parameters (placeholders)
  main.parameters.json     # JSON equivalent of the starter parameters
  modules/log-analytics.bicep
docs/
  Talvex_Landing_Zone_Lab_Guide.md   # portal-first Entra / landing zone lab guide
```

## Prerequisites

- An Azure subscription you can safely experiment in (a free or throwaway lab subscription is ideal)
- Permission to deploy at subscription scope (e.g. Owner on the lab subscription)
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) with Bicep (`az bicep install`)

## Before you deploy: edit the parameters

> ⚠️ **`infra/main.bicepparam` is an UNTESTED STARTER.** It contains placeholders: `orgPrefix = 'contoso'` and `lab-owner@example.com` as the budget alert email. **You must edit these** (and review every other value) and **run a what-if** before any real deployment. The template has not been validated end to end against a live subscription.

## Deploy

Always run **what-if first** and read the output:

```bash
cd infra
az login
az account set --subscription "<your-lab-subscription-id>"

# 1. Preview changes (nothing is created)
az deployment sub what-if \
  --location eastus2 \
  --template-file main.bicep \
  --parameters main.bicepparam

# 2. Only if the preview looks right:
az deployment sub create \
  --location eastus2 \
  --template-file main.bicep \
  --parameters main.bicepparam
```

## Cost note

The design aims for roughly **$0**: Defender plans are Free, the Log Analytics workspace has a daily cap and short retention, and a budget alert is included. **This is a design goal, not a guarantee.** Verify pricing in your own subscription, check the what-if output, watch the budget alert, and delete lab resources when finished. Note that a daily cap stops log ingestion once reached, which is acceptable in a lab but not in production.

## CMMC mapping caveat

The CMMC practice mappings in the lab guide were **written by the repo author** and are not an official or authoritative crosswalk. **Verify every mapping against official Microsoft documentation and the official CMMC / NIST sources** (CMMC Assessment Guide Level 2, NIST SP 800-171 Rev. 2) before relying on it. Nothing here is legal, compliance, or assessment advice.

## License

MIT. See [LICENSE](LICENSE).
