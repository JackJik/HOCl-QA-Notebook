# HOCl QA & R&D Suite — TG Labs / 50MM

Portable Mathematica notebook for **QA troubleshooting** and **R&D simulation** of salt-brine electrolyzed HOCl (50–225 ppm FAC) and 50MM cosmetic hydrogels.

## Open on a MacBook

1. Clone this repo.
2. Double-click `HOCl_QA_Suite.nb` (or open in Mathematica).
3. Evaluate initialization cells / enable dynamics if prompted.
4. Use **QA Bench** or **R&D Engine** from the landing dashboard.

Full user guide: [docs/README.md](docs/README.md)

## Tests

```bash
for t in tests/test_*.wls; do wolframscript -file "$t" || exit 1; done
```

## License / use

Internal TG Labs / 50MM decision-support tool. Not a product-release authority. Confirm all release-critical results with validated lab methods.
