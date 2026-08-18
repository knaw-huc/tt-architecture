# Team Text - Software Architecture Overview

## Introduction

This document presents the wider architecture developed by [Team
Text](https://di.huc.knaw.nl/tekstanalyse-nl.html) at the KNAW Humanities
Cluster. All in-house software mentioned in this documentation can be found via
<https://tools.huc.knaw.nl>.

The document serves both as an internal reference, as well as a technical show-case to
external parties.

## Service Oriented Architecture and Data pipeline for Text Collections

We have ample experience publishing diverse scientific text collections. These
may be literary text editions, historical manuscripts, linguistically-annotated
collections or large corpora from automatic OCR or Handwritten Text
Recognition.

A data processing pipeline takes the original corpus in the form prepared by
the editors, this may be TEI XML, PageXML, FoLiA XML or other formats.

We distinguish the following stages in our pipeline, they are schematically shown below:

1. **Validation** - Validated the corpus as delivered by the editors.
2. **Conversion** - Converts the corpus to plain text and stand-off W3C Web Annotations (via STAM)
    * Normalisation
    * Apparatus Conversion
    * IIIF Manifest Generation
3. **Ingest** - Loads the generated artifacts (plain text, annotations, images) into their respective services

The pipeline itself is driven by GNU Make.

![Data Processing and Service Architecture](artifacts/architecture.png)

### Legend

* Data is shown in yellow
* Processing software is shown in green squares
* Software Services are shown in purple parallelograms
* Communication protocols are shown as arrow labels
* Lines represent the data/provisioning flow
* Software marked with an asterisk is third-party software, all others are developed in-house.

## 3. Data Enrichment pipelines

Most data enrichment pipelines are documented elsewhere (direct links to schemas or READMEs/documentation with schemas):
:

* [Globalise Language Detection pipeline](https://github.com/knaw-huc/globalise-tools/blob/main/pipelines/langdetect/)
* [Globalise Query Expansion pipeline (kweepeer)](https://github.com/knaw-huc/kweepeer)

## 4. Data Models

Data models can be found elsewhere as well (direct links to schemas or READMEs/documentation with schemas):

* [STAM](https://github.com/annotation/stam)
* [Text Fabric](https://annotation.github.io/text-fabric/tf/about/datamodel.html)
* [FoLiA](https://github.com/proycon/folia)
