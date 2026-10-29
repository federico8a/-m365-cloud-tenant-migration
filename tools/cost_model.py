#!/usr/bin/env python3
"""Public-price CAD scenario estimator. Never treats quote-only SKUs as known prices."""
import argparse
import json
from datetime import date
from decimal import Decimal
from pathlib import Path

BASE_CAD = {
    'Business Basic': Decimal('9.50'),
    'Business Standard': Decimal('19.00'),
    'Business Premium': Decimal('29.80'),
    'Microsoft 365 E3': Decimal('52.90'),
    'Microsoft 365 E5': Decimal('81.40'),
    'Office 365 E3': Decimal('35.30'),
    'Office 365 E5': Decimal('55.60'),
}

def estimate(users, overlap_months, sku, sharepoint_gb=0, migration_license_cad=None):
    if users < 1 or overlap_months < 1 or sharepoint_gb < 0:
        raise ValueError('users/overlap months must be positive and GB cannot be negative')
    base = BASE_CAD[sku] * users * overlap_months
    migration = None if migration_license_cad is None else migration_license_cad * users
    native_sp_units = (Decimal(str(sharepoint_gb)) / Decimal('100')).__ceil__()
    return {
        'asOf': '2026-10-29', 'currency': 'CAD', 'license': sku, 'users': users,
        'overlapMonths': overlap_months,
        'destinationLicenseOverlap': str(base),
        'ctudmLicensePerUserCAD': None if migration_license_cad is None else str(migration_license_cad),
        'ctudmOneTimeTotalCAD': None if migration is None else str(migration),
        'nativeSharePoint100GbUnitsIfEAEligible': native_sp_units,
        'nativeSharePointLicenseCostCAD': None,
        'unknownCosts': ['SharePoint site move EA-only quote or third-party vendor',
                         'Source licensing commitment and annual billing beyond overlap',
                         'Power Platform/Fabric/Teams Phone/Defender/Purview as needed',
                         'Consulting, tax, carrier, downtime, backup, vendor tools'],
        'partialKnownTotalCAD': str(base + (migration or Decimal('0'))),
        'warning': 'PARTIAL ESTIMATE. Not a binding quote or complete total; no default price invented for migration SKU.'
    }

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--users', required=True, type=int)
    p.add_argument('--overlap-months', type=int, default=2)
    p.add_argument('--license', choices=BASE_CAD, default='Business Premium')
    p.add_argument('--sharepoint-gb', type=float, default=0)
    p.add_argument('--ctudm-quoted-cad-per-user', type=Decimal)
    p.add_argument('--output')
    args = p.parse_args()
    result=estimate(args.users,args.overlap_months,args.license,args.sharepoint_gb,args.ctudm_quoted_cad_per_user)
    payload=json.dumps(result,indent=2)
    print(payload)
    if args.output:
        out=Path(args.output)
        out.parent.mkdir(parents=True,exist_ok=True)
        out.write_text(payload+'\n',encoding='utf-8')
if __name__ == '__main__':
    main()
