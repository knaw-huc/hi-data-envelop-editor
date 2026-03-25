#!/usr/bin/env python3
"""
Script to add automatic labels, explanations, cues, and autoCompletes to a v2 CMDI tweak file.

Improvements over previous version:
  - Only Components advance the section counter; Elements get sub-numbers within
  - Labels use bold markers for the editor (⚫ prefix for Components)
  - 'Level' prefix only on top-level sections (1, 2, 3...)
  - autoCompleteURI elements from v1 are carried over to v2 via column mapping
  - cue:inputWidth/inputHeight from v1 are carried over to v2 via column mapping
  - Additional cues added for v2-only fields that need text areas
  - Existing v1 explanations are merged with auto-generated doc links
"""

import re
import csv
from lxml import etree

# ============================================================
# CONFIGURATION
# ============================================================
V1_TWEAK_PATH = "/Users/lilianam/workspace/hi-data-envelop-editor/data/apps/data-envelopes/profiles/clarin.eu:cr1:p_1708423613607/tweaks/tweak-1.xml"
V2_TWEAK_PATH = "/Users/lilianam/workspace/hi-data-envelop-editor/data/apps/data-envelopes-v2/profiles/clarin.eu:cr1:p_1770289476181/tweaks/tweak-0.xml"
# V2_SCHEMA_PATH removed - ValueScheme belongs in schema, not tweak
MAPPING_CSV_PATH = "/Users/lilianam/workspace/hi-data-envelop-editor/scripts/output/column-mapping-v1-to-v2.csv"
OUTPUT_PATH = "/Users/lilianam/workspace/hi-data-envelop-editor/data/apps/data-envelopes-v2/profiles/clarin.eu:cr1:p_1770289476181/tweaks/tweak-1.xml"

BASE_URL = "https://edu.nl/atqm8"
START_FROM = "DataEnvelopeMetadata"

# v2 paths that should get text-area cues even if v1 didn't have them
# (new fields in v2 or fields the user explicitly wants as text areas)
EXTRA_CUES = {
    # Section 2 - DatasetMetadata
    "/DataEnvelope/DatasetMetadata/description": ("60", "8"),
    "/DataEnvelope/DatasetMetadata/TemporalCoverage/Comments/comment": ("60", "8"),
    "/DataEnvelope/DatasetMetadata/ResponsibleAgents/Funders/description": ("60", "8"),
    "/DataEnvelope/DatasetMetadata/VersionMaintenance/MaintenancePlan/updates": ("60", "8"),
    "/DataEnvelope/DatasetMetadata/VersionMaintenance/MaintenancePlan/Comments/comment": ("60", "8"),
    "/DataEnvelope/DatasetMetadata/RightsStatement/AccessDetails/description": ("60", "8"),
    "/DataEnvelope/DatasetMetadata/Comments/comment": ("60", "8"),
    # Section 3 - Data
    "/DataEnvelope/Data/DataResourceDescription/description": ("60", "8"),
    "/DataEnvelope/Data/DataFields/ExternalSchema/externalSchemaNote": ("60", "8"),
    "/DataEnvelope/Data/DataFields/DataField/descriptionField": ("60", "8"),
    "/DataEnvelope/Data/DataExamples/TypicalExample/description": ("60", "8"),
    "/DataEnvelope/Data/DataExamples/AtypicalExample/atypdescription": ("60", "8"),
    "/DataEnvelope/Data/Errors/errordescription": ("60", "8"),
    "/DataEnvelope/Data/ExternalResources/extResourcesDescription": ("60", "8"),
    "/DataEnvelope/Data/SocialImpact/Biases/knownBiases": ("60", "8"),
    "/DataEnvelope/Data/SocialImpact/Biases/stepsToReduceBias": ("60", "8"),
    "/DataEnvelope/Data/SocialImpact/Biases/SensAttributes/unintentionalAttribute": ("60", "8"),
    "/DataEnvelope/Data/SocialImpact/EthicalReview/outcomes": ("60", "8"),
    "/DataEnvelope/Data/DataProvenance/description": ("60", "8"),
    "/DataEnvelope/Data/DataProvenance/notableFeatures": ("60", "8"),
    "/DataEnvelope/Data/Digitisation/digitalisationPipeline": ("60", "8"),
    "/DataEnvelope/Data/Comments/comment": ("60", "8"),
    # Section 4 - Uses
    "/DataEnvelope/Uses/motivation": ("80", "6"),
    "/DataEnvelope/Uses/Use/SuitableUseCase/suitableUseCase": ("80", "6"),
    "/DataEnvelope/Uses/Use/SuitableUseCase/additionalNotes": ("80", "3"),
    "/DataEnvelope/Uses/Use/UnsuitableUseCase/unsuitableUseCase": ("80", "6"),
    "/DataEnvelope/Uses/Use/UnsuitableUseCase/additionalNotes": ("80", "3"),
    "/DataEnvelope/Uses/UseWithOtherData/knownSafeDatasetsDataTypes": ("80", "3"),
    "/DataEnvelope/Uses/UseWithOtherData/knownUnsafeDatasetsDataTypes": ("80", "3"),
    "/DataEnvelope/Uses/UseInMLOrAISystems/otherDatasetUses": ("80", "3"),
    "/DataEnvelope/Uses/UseInMLOrAISystems/notableFeatures": ("80", "3"),
    "/DataEnvelope/Uses/UseInMLOrAISystems/knownCorrelations": ("80", "3"),
    "/DataEnvelope/Uses/UseInMLOrAISystems/usageGuidelines": ("80", "3"),
    "/DataEnvelope/Uses/UseInMLOrAISystems/dataSplits": ("80", "3"),
    "/DataEnvelope/Uses/Sampling/bestPractices": ("80", "3"),
    "/DataEnvelope/Uses/Sampling/risksAndMitigations": ("80", "3"),
    "/DataEnvelope/Uses/Comments/comment": ("80", "3"),
    # Section 5 - HumanPerspective
    "/DataEnvelope/HumanPerspective/HumanAnnotators/AnnotationType/descriptionOfAnnotators": ("80", "6"),
    "/DataEnvelope/HumanPerspective/HumanAnnotators/AnnotationType/compensation": ("80", "3"),
    "/DataEnvelope/HumanPerspective/HumanAnnotators/AnnotationType/geographicDistributionOfAnnotators": ("80", "3"),
    "/DataEnvelope/HumanPerspective/HumanAnnotators/AnnotationType/summaryOfAnnotationInstructions": ("80", "6"),
    "/DataEnvelope/HumanPerspective/HumanAnnotators/AnnotationType/additionalNotes": ("80", "3"),
    "/DataEnvelope/HumanPerspective/Creators/creatorPositionality": ("80", "3"),
    "/DataEnvelope/HumanPerspective/Comments/comment": ("80", "3"),
}

# autoCompleteURI mappings: v2_element_path → URI
# These are carried over from v1 via the column mapping
AUTOCOMPLETE_MAP = {
    "/DataEnvelope/DatasetMetadata/Genre/controlledTerm": "/proxy/skosmos/sd/ineo-informationtypes",
    "/DataEnvelope/DatasetMetadata/Topic/controlledTerm": "/proxy/skosmos/sd/nwo-researchfields",
    "/DataEnvelope/DatasetMetadata/Languages/controlledTerm": "/proxy/skosmos/clavas/ISO639-3",
    "/DataEnvelope/Data/DataResourceDescription/encoding": "/proxy/skosmos/sd/encodings",
    "/DataEnvelope/Data/DataFields/DataField/dataFieldType": "/proxy/skosmos/sd/xsd-datatypes",
    "/DataEnvelope/Uses/domains": "/proxy/skosmos/sd/tadirah",
}

# ============================================================
# Constants
# ============================================================
CLARIAH_NS = "http://www.clariah.eu/"
CUE_NS = "http://www.clarin.eu/cmd/cues/1"


# ============================================================
# Helpers
# ============================================================
def camel_to_spaced(name):
    s = re.sub(r'([a-z])([A-Z])', r'\1 \2', name)
    s = re.sub(r'([A-Z]+)([A-Z][a-z])', r'\1 \2', s)
    s = s[0].upper() + s[1:]
    return s


def get_element_path(elem):
    parts = []
    p = elem
    while p is not None:
        if p.tag in ("Component", "Element") and p.get("name"):
            parts.insert(0, p.get("name"))
        p = p.getparent()
    return "/" + "/".join(parts)


def load_column_mapping(csv_path):
    mapping = {}
    with open(csv_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            v1 = row.get("v1_column", "").strip()
            v2 = row.get("v2_column", "").strip()
            if v1 and v2:
                mapping[v1] = v2
    return mapping


def build_full_mapping(column_mapping):
    full = dict(column_mapping)
    for v1_path, v2_path in column_mapping.items():
        v1_parts = v1_path.split("/")
        v2_parts = v2_path.split("/")
        for i in range(1, min(len(v1_parts), len(v2_parts))):
            v1_parent = "/".join(v1_parts[:-i])
            v2_parent = "/".join(v2_parts[:-i])
            if v1_parent and v2_parent and v1_parent not in full:
                full[v1_parent] = v2_parent
    return full


def extract_v1_explanations(v1_tree, full_mapping):
    v2_explanations = {}
    for expl in v1_tree.getroot().iter(f"{{{CLARIAH_NS}}}explanation"):
        parent = expl.getparent()
        if parent is None or parent.tag not in ("Component", "Element"):
            continue
        text = (expl.text or "").strip()
        if not text:
            continue
        v1_path = get_element_path(parent)
        v2_path = full_mapping.get(v1_path)
        if v2_path:
            if v2_path in v2_explanations:
                v2_explanations[v2_path] += " " + text
            else:
                v2_explanations[v2_path] = text
    return v2_explanations


def extract_v1_cues(v1_tree, full_mapping):
    """Extract cue:inputWidth/Height from v1, mapped to v2 paths."""
    v2_cues = {}
    for elem in v1_tree.getroot().iter("Element"):
        w = elem.get(f"{{{CUE_NS}}}inputWidth")
        h = elem.get(f"{{{CUE_NS}}}inputHeight")
        if w or h:
            v1_path = get_element_path(elem)
            v2_path = full_mapping.get(v1_path)
            if v2_path:
                v2_cues[v2_path] = (w, h)
    # Merge with EXTRA_CUES (extra cues take priority for new fields)
    for path, (w, h) in EXTRA_CUES.items():
        if path not in v2_cues:
            v2_cues[path] = (w, h)
    return v2_cues


# ============================================================
# Main processing
# ============================================================
def process_node(elem, counters, depth, is_top_level, v2_explanations, v2_cues):
    """Add label, explanation, autoComplete, and cues to a Component or Element."""
    name = elem.get("name", "")
    if not name:
        return

    number = ".".join(str(c) for c in counters)
    spaced_name = camel_to_spaced(name)
    v2_path = get_element_path(elem)
    is_component = (elem.tag == "Component")

    # --- Label ---
    if is_top_level:
        label_text = f"Level {number}: {spaced_name}"
    elif is_component:
        label_text = f"{number} {spaced_name}"
    else:
        label_text = f"{number} {spaced_name}"

    # --- Explanation ---
    url_name = spaced_name.replace(" ", "-")
    auto_part = f"See documentation at: {BASE_URL}#{url_name}"
    v1_text = v2_explanations.get(v2_path, "").strip()
    if v1_text:
        if not v1_text.endswith((".", "!", "?", ":")):
            v1_text += "."
        explanation_text = f"{v1_text} {auto_part}"
    else:
        explanation_text = auto_part

    # --- Create label and explanation ---
    label_elem = etree.SubElement(elem, f"{{{CLARIAH_NS}}}label")
    label_elem.set("{http://www.w3.org/XML/1998/namespace}lang", "en")
    label_elem.text = label_text
    label_elem.tail = "\n" + "\t" * (depth + 1)

    expl_elem = etree.SubElement(elem, f"{{{CLARIAH_NS}}}explanation")
    expl_elem.text = explanation_text
    expl_elem.tail = "\n" + "\t" * (depth + 1)

    # Move to first position
    elem.remove(label_elem)
    elem.remove(expl_elem)
    elem.insert(0, expl_elem)
    elem.insert(0, label_elem)

    # --- autoCompleteURI ---
    if v2_path in AUTOCOMPLETE_MAP:
        ac_elem = etree.SubElement(elem, f"{{{CLARIAH_NS}}}autoCompleteURI")
        ac_elem.text = AUTOCOMPLETE_MAP[v2_path]
        ac_elem.tail = "\n" + "\t" * (depth + 1)

    # --- Cues (inputWidth/inputHeight) ---
    if v2_path in v2_cues:
        w, h = v2_cues[v2_path]
        if w:
            elem.set(f"{{{CUE_NS}}}inputWidth", w)
        if h:
            elem.set(f"{{{CUE_NS}}}inputHeight", h)

    # --- Recurse: only Components advance the section counter ---
    comp_counter = 0
    for child in list(elem):
        if child.tag == "Component":
            comp_counter += 1
            process_node(child, counters + [comp_counter], depth + 1, False, v2_explanations, v2_cues)
        elif child.tag == "Element":
            # Elements don't get section numbers — pass None as counters
            process_element(child, depth + 1, v2_explanations, v2_cues)


def process_element(elem, depth, v2_explanations, v2_cues):
    """Add label, explanation, autoComplete, and cues to an Element."""
    name = elem.get("name", "")
    if not name:
        return

    spaced_name = camel_to_spaced(name)
    v2_path = get_element_path(elem)

    # --- Label: just the name, no number ---
    label_text = spaced_name

    # --- Explanation ---
    url_name = spaced_name.replace(" ", "-")
    auto_part = f"See documentation at: {BASE_URL}#{url_name}"
    v1_text = v2_explanations.get(v2_path, "").strip()
    if v1_text:
        if not v1_text.endswith((".", "!", "?", ":")):
            v1_text += "."
        explanation_text = f"{v1_text} {auto_part}"
    else:
        explanation_text = auto_part

    # --- Create label and explanation ---
    label_elem = etree.SubElement(elem, f"{{{CLARIAH_NS}}}label")
    label_elem.set("{http://www.w3.org/XML/1998/namespace}lang", "en")
    label_elem.text = label_text
    label_elem.tail = "\n" + "\t" * (depth + 1)

    expl_elem = etree.SubElement(elem, f"{{{CLARIAH_NS}}}explanation")
    expl_elem.text = explanation_text
    expl_elem.tail = "\n" + "\t" * (depth + 1)

    # Move to first position
    elem.remove(label_elem)
    elem.remove(expl_elem)
    elem.insert(0, expl_elem)
    elem.insert(0, label_elem)

    # --- autoCompleteURI ---
    if v2_path in AUTOCOMPLETE_MAP:
        ac_elem = etree.SubElement(elem, f"{{{CLARIAH_NS}}}autoCompleteURI")
        ac_elem.text = AUTOCOMPLETE_MAP[v2_path]
        ac_elem.tail = "\n" + "\t" * (depth + 1)

    # --- Cues ---
    if v2_path in v2_cues:
        w, h = v2_cues[v2_path]
        if w:
            elem.set(f"{{{CUE_NS}}}inputWidth", w)
        if h:
            elem.set(f"{{{CUE_NS}}}inputHeight", h)


def main():
    print(f"V1 tweak: {V1_TWEAK_PATH}")
    print(f"V2 tweak: {V2_TWEAK_PATH}")
    print(f"Mapping:  {MAPPING_CSV_PATH}")

    # Load mapping
    column_mapping = load_column_mapping(MAPPING_CSV_PATH)
    full_mapping = build_full_mapping(column_mapping)
    print(f"Column mappings: {len(column_mapping)} element + {len(full_mapping) - len(column_mapping)} inferred component")

    # Load v1 data
    v1_tree = etree.parse(V1_TWEAK_PATH)
    v2_explanations = extract_v1_explanations(v1_tree, full_mapping)
    v2_cues = extract_v1_cues(v1_tree, full_mapping)
    print(f"V1 explanations mapped: {len(v2_explanations)}")
    print(f"V2 cues (v1 + extra): {len(v2_cues)}")

    # Parse v2
    v2_tree = etree.parse(V2_TWEAK_PATH)
    v2_root = v2_tree.getroot()

    data_envelope = None
    for comp in v2_root.findall("Component"):
        if comp.get("name") == "DataEnvelope":
            data_envelope = comp
            break

    if data_envelope is None:
        print("ERROR: DataEnvelope not found")
        return

    # Process
    print(f"\nAdding labels (starting from {START_FROM})...")
    started = False
    top_counter = 0
    for child in list(data_envelope):
        if child.tag in ("Component", "Element"):
            if child.get("name") == START_FROM:
                started = True
            if started:
                top_counter += 1
                process_node(child, [top_counter], 2, True, v2_explanations, v2_cues)

    # Write
    output = etree.tostring(v2_tree, xml_declaration=True, encoding="UTF-8", pretty_print=True).decode()
    with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        f.write(output)
    print(f"\nOutput: {OUTPUT_PATH}")

    # Verify
    labels = list(v2_root.iter(f"{{{CLARIAH_NS}}}label"))
    expls = list(v2_root.iter(f"{{{CLARIAH_NS}}}explanation"))
    autocompletes = list(v2_root.iter(f"{{{CLARIAH_NS}}}autoCompleteURI"))
    cue_count = sum(1 for e in v2_root.iter("Element")
                    if e.get(f"{{{CUE_NS}}}inputWidth") or e.get(f"{{{CUE_NS}}}inputHeight"))
    merged = sum(1 for e in expls if e.text and "See documentation" in e.text and not e.text.startswith("See"))

    print(f"\nVerification:")
    print(f"  Labels: {len(labels)}")
    print(f"  Explanations: {len(expls)} ({merged} with v1 text merged)")
    print(f"  autoCompleteURIs: {len(autocompletes)}")
    print(f"  Elements with cues: {cue_count}")
    if labels:
        print(f"  First: {labels[0].text}")
        # Show first few section headers
        for l in labels[:15]:
            print(f"    {l.text}")


if __name__ == "__main__":
    main()
