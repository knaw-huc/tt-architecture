# Team Text - Software Architecture Overview

## Introduction

This document presents the wider architecture developed by [Team
Text](https://di.huc.knaw.nl/tekstanalyse-nl.html) at the KNAW Humanities
Cluster. All in-house software mentioned in this documentation can be found via
<https://tools.huc.knaw.nl>.

The document serves both as an internal reference, as well as a technical show-case to
external parties.

## 1. Service Oriented Architecture for Text Collections

We have ample experience publishing diverse scientific text collections. These
may be literary text editions, historical manuscripts, linguistically-annotated
collections or large corpora from automatic OCR or Handwritten Text
Recognition. 

### 1.1. Current SOA for Text Collections

This is our current Service Oriented Architecture for making available
(enriched) Text Collections, it still includes uses of TextRepo.
[TextAnnoViz](https://github.com/knaw-huc/textannoviz) is the frontend that
end-users will deal with mostly, via their web browsers, to browse and search
texts, their original scans and annotations on either.

```mermaid
%%{init: {"flowchart": {"htmlLabels": true},
    'themeVariables': {
      'edgeLabelBackground': 'transparent'
    }
}}%%
flowchart TD


    user@{ shape: sl-rect, label: "End-user (Researcher)<br>in web browser"}
    user -- "HTTPS (UI)" --> textannoviz
    subgraph frontend
        textannoviz[/"<b>TextAnnoViz</b><br>(web front-end)"/]
        mirador@{shape: subproc, label: "Mirador<br><i>IIIF Image viewer</i>"}
        textannoviz --> mirador
    end

    techuser@{ shape: sl-rect, label: "Technical user/machine<br>via a web client"}

    techuser -- "HTTPS + Broccoli API" --> broccoli
    subgraph middleware
        textannoviz -- "HTTPS + Broccoli API" --> broccoli
        broccoli[/"<b>Broccoli</b><br><i>(broker)</i>"/]

        broccoli_annorepoclient@{shape: subproc, label: "annorepo-client (java)"}
        broccoli --> broccoli_annorepoclient 
    end


    subgraph backend
    
        annorepo[/"<b>Annorepo</b><br><i>(web annotation server)</i>"/]
        mongodb[/"MongoDB<br><i>(NoSQL database server)</i>"/]
        annorepo_db[("Annotation Database")]
        annorepo -- "HTTP(S) + MongoDB Query API" --> mongodb --> annorepo_db


        textscans@{ shape: docs, label: "Text Scans<br><i>(image files)</i>"}
        textdb@{ shape: database, label: "Texts (with metadata) database"}

        textrepo[/"<b>Textrepo</b><br><i>(text server)</i>"/]
        postgresql[/"Postgresql<br><i>(Database System)</i>"/]

        subgraph brinta
            broccoli -- "HTTP(S) + ElasticSearch API" --> elasticsearch
            elasticsearch[/"ElasticSearch<br><i>(Search engine)</i>"/]
            searchindex[("Text and annotation index<br><i>(for full text text search and faceted search)</i>")]
            elasticsearch --> searchindex
        end

        textrepo -- "Postgresql" --> postgresql

        postgresql --> textdb

        cantaloupe[/"<b>Cantaloupe</b><br><i>(IIIF Image server)</i>"/]
        manifests@{ shape: docs, label: "IIIF Manifests"}
        cantaloupe --> textscans

        broccoli_annorepoclient -- "HTTP(S) + W3C Web Annotation Protocol" --> annorepo
        broccoli -- "HTTP(S) + TextRepo API" --> textrepo

        manifest_server[/"nginx<br><i>(static manifest server)</i>"/]
        manifest_server --> manifests


        mirador -- "HTTPS + IIIF Image API" --> cantaloupe
        mirador -- "HTTPS" --> manifest_server
    end


    classDef thirdparty fill:#ccc,color:#111
    class cantaloupe,mongodb,elasticsearch,postgresql,mirador,manifest_server thirdparty

    linkStyle default background:transparent,color:#009
```

#### Legend

* Arrows follow caller (or loader) direction, response data flows in opposite direction. Edge labels denote communication protocols.
* Rectangles represent processes.
* Parallelograms represent networked processes (i.e. services).
* Rectangles with an extra marked block left and right represent software libraries
* Third party software is grayed out
* All components (in any of frontend, middleware, and backend) are configurable via external configuration files. These are not explicitly drawn in the schema.

#### Notes

* Web annotations produced by this pipeline have custom selectors for TextRepo that are not part of the W3C Web Annotation Data model.

### 1.2. New proposed SOA for Text Collections 

This is our new proposed Service Oriented Architecture for making available (enriched) Text Collections, it switches out Textrepo for textsurf and adds a query expansion service (kweepeer).

```mermaid
%%{init: {"flowchart": {"htmlLabels": true},
    'themeVariables': {
      'edgeLabelBackground': 'transparent'
    }
}}%%
flowchart TD


    user@{ shape: sl-rect, label: "End-user (Researcher)<br>in web browser"}
    user -- "HTTPS (UI)" --> textannoviz
    user -- "HTTPS (UI)" --> annorepodashboard
    subgraph frontend
        textannoviz[/"<b>TextAnnoViz</b><br>(web front-end)"/]
        mirador@{shape: subproc, label: "Mirador<br><i>IIIF Image viewer</i>"}
        kweepeerfrontend@{shape: subproc, label: "Kweepeer Frontend<br><i>(Query expansion UI)</i>"}
        textannoviz --> mirador
        textannoviz --> kweepeerfrontend

        annorepodashboard[/"<b>AnnoRepo Dashboard</b><br>(explorative and administrative front-end for annotations)"/]
    end

    techuser@{ shape: sl-rect, label: "Technical user/machine<br>via a web client"}

    techuser -- "HTTPS + Broccoli API" --> broccoli
    subgraph middleware
        textannoviz -- "HTTPS + Broccoli API" --> broccoli
        broccoli[/"<b>Broccoli</b><br><i>(broker)</i>"/]

        broccoli_annorepoclient@{shape: subproc, label: "annorepo-client (java)"}
        broccoli_elasticclient@{shape: subproc, label: "elasticsearch-java<br><i>(client)</i>"}
        broccoli --> broccoli_annorepoclient 
        broccoli --> broccoli_elasticclient 
    end


    subgraph backend
    
        annorepo[/"<b>Annorepo</b><br><i>(web annotation server)</i>"/]
        mongodb[/"MongoDB<br><i>(NoSQL database server)</i>"/]
        annorepo_db[("Annotation Database")]
        annorepo --> mongodb --> annorepo_db
        annorepodashboard --> annorepo

        subgraph brinta
            broccoli_elasticclient -- "HTTP(S) + ElasticSearch API" --> elasticsearch
            elasticsearch[/"ElasticSearch<br><i>(Search engine)</i>"/]
            searchindex[("Text and annotation index<br><i>(for full text text search and faceted search)</i>")]
            elasticsearch --> searchindex
        end

        texts@{ shape: docs, label: "Text files<br><i>(plain text, UTF-8)</i>"}
        textscans@{ shape: docs, label: "Text Scans<br><i>(image files)</i>"}

        textsurf[/"<b>Textsurf</b><br>(text server)"/]
        textframe@{shape: subproc, label: "Textframe<br><i>(text referencing library)</i>"}


        cantaloupe[/"<b>Cantaloupe</b><br><i>(IIIF Image server)</i>"/]
        manifests@{ shape: docs, label: "IIIF Manifests"}
        cantaloupe --> textscans

        kweepeer[/"<b>Kweepeer</b><br><i>(Query Expansion server)</i>"/]

        broccoli_annorepoclient -- "HTTP(S) + W3C Web Annotation Protocol" --> annorepo
        broccoli -- "HTTP(S) + Textsurf API" --> textsurf

        mirador -- "HTTPS" --> manifest_server
        mirador -- "HTTPS + IIIF Image API" --> cantaloupe

        kweepeerfrontend -- "HTTP(S) + Kweepeer API" --> kweepeer

        manifest_server[/"nginx<br><i>(static manifest server)</i>"/]
        manifest_server --> manifests

        textsurf --> textframe -->  texts
        textsurf --> texts
    end


    classDef thirdparty fill:#ccc,color:#111
    class cantaloupe,mongodb,elasticsearch,postgresql,mirador,manifest_server,broccoli_elasticclient thirdparty

    linkStyle default background:transparent,color:#009
```

#### Notes

* Kweepeer is not further expanded in this schema, see [https://github.com/knaw-huc/kweepeer/blob/master/README.md#architecture](this schema) for further expansion.
* Web annotations produced by this pipeline no longer have custom selectors but fully adhere to the standard.
* All components (in any of frontend, middleware, and backend) are configurable via external configuration files. These are not explicitly drawn in the schema.

### 1.3. Potential SOA for Text Collections with STAM

This is a potential and highly experimental architecture that trades out various components for [STAM](https://annotation.github.io/stam)-based solutions. Though STAM is implemented, it is currently not integrated into such a wider architecture. It is presented here merely as an option for consideration.

```mermaid
%%{init: {"flowchart": {"htmlLabels": true},
    'themeVariables': {
      'edgeLabelBackground': 'transparent'
    }
}}%%
flowchart TD


    user@{ shape: sl-rect, label: "End-user (Researcher)<br>in web browser"}
    user -- "HTTPS (UI)" --> textannoviz
    subgraph frontend
        textannoviz[/"<b>TextAnnoViz</b><br>(web front-end)"/]
        mirador@{shape: subproc, label: "Mirador<br><i>IIIF Image viewer</i>"}
        textannoviz --> mirador

        tavconf@{ shape: doc, label: "TextAnnoViz Configuration<br><i>(project specific)</i>"}
        textannoviz --> tavconf
    end

    techuser@{ shape: sl-rect, label: "Technical user/machine<br>via a web client"}

    techuser -- "HTTPS + Broccoli API" --> broccoli
    subgraph middleware
        textannoviz -- "HTTPS + Broccoli API" --> broccoli
        broccoli[/"<b>Broccoli</b><br><i>(broker)</i>"/]

        broccoli --> brocconf
        brocconf@{ shape: doc, label: "Broccoli Configuration<br><i>(project specific)</i>"}
    end

    textannoviz -. "HTTP(S) + W3C Web Annotation protocol (subset)<br>, STAM text referencing API<br>and/or STAM Query Language<br>" -.-> stamd

    subgraph backend

        stamd[/"<b>stamd</b><br><i>(text and annotation server)</i>"/]

        stamrust@{shape: subproc, label: "stam-rust<br><i>(STAM library)</i>"}

        stamrust --> textframe
   
        texts@{ shape: docs, label: "Text files<br><i>(plain text, UTF-8)</i>"}
        annotations@{ shape: docs, label: "STAM Annotations<br><i>(STAM JSON/CBOR)</i>"}
        textscans@{ shape: docs, label: "Text Scans<br><i>(image files)</i>"}
        textframe@{shape: subproc, label: "Textframe<br><i>(text referencing library)</i>"}


        cantaloupe[/"<b>Cantaloupe</b><br><i>(IIIF Image server)</i>"/]
        manifests@{ shape: docs, label: "IIIF Manifests"}
        cantaloupe --> textscans

        broccoli -- "HTTP(S) + W3C Web Annotation protocol (subset)<br>, STAM text referencing API<br>and/or STAM Query Language<br>" --> stamd

        mirador -- "HTTPS" --> manifest_server
        mirador -- "HTTPS + IIIF Image API" --> cantaloupe

        manifest_server[/"nginx<br><i>(static manifest server)</i>"/]
        manifest_server --> manifests

        stamd --> stamrust
        textframe --> texts
        stamrust --> annotations
    end


    classDef thirdparty fill:#ccc,color:#111
    class cantaloupe,mirador,manifest_server,broccoli_elasticclient thirdparty

    linkStyle default background:transparent,color:#009
```

#### Notes

* There are three major caveats here currently:
    * The STAM library does not provide a full-text index [yet](https://github.com/annotation/stam-rust/issues/22) and it is not a drop-in replacement for Elastic Search.
    * The STAM implementation is currently memory-bound, which means all annotations are loaded into memory (which makes it very fast) and this will not scale to huge corpora
        * The same goes for the texts themselves, but a solution to that is already proposed in this architecture (but not implemented); using textframe in stamd.
    * The caller logic in Broccoli (or potentially in TextAnnoviz, see next point) would change drastically
        * The entire middleware layer (the broker) can be omitted entirely if the caller logic is implemented into TextAnnoViz. The dotted line represents this option.

## 2. Data Conversion Pipelines

### 2.1. Current conversion pipeline for Text Collections

[Text Fabric [Factory]](https://github.com/annotation/text-fabric-factory) and [un-t-ann-gle](https://github.com/knaw-huc/un-t-ann-gle) are used in the Suriano, Translatin, Van Gogh and Mondriaan projects. Untangle is used standlone in Republic (CAF data) and Globalise (PageXML data).


```mermaid
%%{init: {"flowchart": {"htmlLabels": true}} }%%
flowchart TD

    subgraph sources["Sources (pick one)"]
        direction LR
        teisource@{ shape: docs, label: "Enriched texts<br>(TEI XML)"}
        pagexmlsource@{ shape: docs, label: "Enriched texts<br>(Page XML)"}
        cafsource@{ shape: docs, label: "Enriched texts<br>(CAF)"}
    end

    user@{ shape: sl-rect, label: "End-user (Data manager)<br>in web browser"}
    user -- "HTTPS (UI)" --> peen

    subgraph frontend
        peen[/"<b>Preview Editor's ENvironment</b> (PEEN)"/]
    end

    subgraph conversion
        direction TB

        peen --> with_textfabric_factory

        subgraph with_textfabric_factory["With Text Fabric Factory (Python API)"]
            direction TB
            teisource ==> tff_fromtei_validation
            pagexmlsource ==> tff_fromxml
            tff_fromtei_validation["tff.convert.tei<br><i>(Validation step)</i>"]
            tff_fromtei_validation ==> tff_fromtei_conversion
            tff_fromtei_conversion["tff.convert.tei<br><i>(Conversion step, from TEI to TF)</i>"]


            tff_iiif["tff.convert.iiif<br><i>(IIIF Manifest generation)</i>"]

            tff_fromxml["tff.convert.xml"]
            tfdata@{ shape: docs, label: "<b>Text Fabric Data</b>"}
            tff_watm["tff.convert.watm<br><i>(Conversion step)</i>"]
            watm@{ shape: docs, label: "WATM (Web Annotation Text Model)<br><i>(internal intermediary representation)</i>"}
            tff_fromtei_conversion ==> tfdata 
            tff_fromxml ==> tfdata
            tfdata ==> tff_iiif ==> manifests
            tfdata ==> tff_watm ==> watm
            manifests@{ shape: docs, label: "IIIF manifests<br>(to be served statically)"}
        end 

        with_textfabric_factory ~~~ editem_apparatus
        peen --> editem_apparatus
        teisource ==> editem_apparatus
        editem_apparatus["editem-apparatus<br><i>(Extract structured data from apparatus TEI)</i>"]
        apparatus_json@{ shape: docs, label: "Apparatus data (JSON)<br><i>(to be served statically)</i>"}
        editem_apparatus ==> apparatus_json
        peen --> with_untanngle

        subgraph with_untanngle["With un-t-ann-gle"]
            direction TB
            watm ==> untanngle_tf
            untanngle_tf["<b>untanngle.tf</b><br><i>(Create texts and web annotations from WATM/TF joined data)</i>"]
            untanngle_tf ==> untanngle_uploader

            untanngle_conversion["<b>un-t-ann-gle</b><br><i>(Project specific conversion pipelines to create texts and webannotations from joined data)</i>>"]
            pagexmlsource == (in globalise project) ==> untanngle_conversion
            cafsource == (in republic project) ==> untanngle_conversion
            untanngle_conversion ==> untanngle_uploader

            untanngle_uploader["<b>un-t-ann-gle uploader</b><br><i>(Generic uploader for annorepo/textrepo)</i>"]

            untanngle_annorepo_client@{shape: subproc, label: "annorepo-client (python)"}
            untanngle_textrepo_client@{shape: subproc, label: "textrepo-client (python)"}

            webanno@{ shape: docs, label: "<b>W3C Web Annotations</b><br><i>(Stand-off annotations, JSONL)</i>"}
            textsegments@{ shape: docs, label: "<b>Text Segments</b><br><i>(JSON for Textrepo)</i>"}


            untanngle_uploader ==> textsegments ==> untanngle_textrepo_client
            untanngle_uploader ==> webanno ==> untanngle_annorepo_client
        end
    end

    subgraph ingest
        direction TB
        untanngle_annorepo_client -- "HTTPS POST/PUT + W3C Web Annotation Protocol" --> annorepo
        untanngle_textrepo_client -- "HTTPS POST/PUT + TextRepo API" --> textrepo

        techuser@{ shape: sl-rect, label: "Technical user/machine<br>via a web client"}
        techuser --> indexer

        annorepo[/"<b>Annorepo</b><br><i>(web annotation server)</i>"/]
        mongodb[/"MongoDB<br><i>(NoSQL database server)</i>"/]
        annorepo_db[("Annotation Database")]
        annorepo --> mongodb --> annorepo_db


        indexer["<b>Indexer</b><br><i>(project-specific, multiple implementations exist)</i>"]

        peen --> indexer
        indexer -- "HTTP(S) GET" --> annorepo
        indexer -- "HTTP(S) GET" --> textrepo

        textrepo[/"<b>Textrepo</b><br><i>(text server)</i>"/]
        postgresql[/"Postgresql<br><i>(Database System)</i>"/]

        textrepo -- "Postgresql" --> postgresql

        indexer -- "HTTP(S) POST + ElasticSearch API" --> elasticsearch

        subgraph brinta
            elasticsearch[/"ElasticSearch<br><i>(Search engine)</i>"/]
            searchindex[("Text and annotation index<br><i>(for full text text search and faceted annotation search)</i>")]
            elasticsearch --> searchindex
        end

        
    end

    sources ~~~ conversion ~~~ ingest


    classDef thirdparty fill:#ccc,color:#111
    class mongodb,elasticsearch,postgresql thirdparty

    classDef abstract color:#f00
    class indexer abstract

    linkStyle default background:transparent,color:#009
```

#### Legend

* Thick lines represent data flow rather than caller direction
* Node with red text denote abstractions rather than specific software 

### 2.3. Conversion with STAM

This pipeline with [STAM](https://annotation.github.io/stam) is currently used in the [Brieven van Hooft project](https://github.com/knaw-huc/brieven-van-hooft-pipeline) (with FoLiA source) and also tested for Van Gogh. This pipeline does not have scans.

```mermaid
%%{init: {"flowchart": {"htmlLabels": true}} }%%
flowchart TD

    subgraph sources["Sources (pick one)"]
        direction LR
        teisource@{ shape: docs, label: "Enriched texts<br>(TEI XML)"}
        foliasource@{ shape: docs, label: "Enriched texts<br>(FoLiA XML)"}
        pagexmlsource@{ shape: docs, label: "Enriched texts<br>(Page XML)"}
    end

    techuser@{ shape: sl-rect, label: "Technical user<br>(command-line)"}
    techuser --> conversion

    subgraph conversion
        direction LR
        subgraph with_folia_tools["with FoLiA-tools (CLI)"]
            direction TB
            foliasource ==> folia2stam
            folia2stam["folia2stam<br><i>converts/untangles FoLiA XML to STAM</i>"]
        end

        subgraph with_stam_tools["with stam-tools (CLI)"]
            direction TB
            stam_xmlconfig@{ shape: docs, label: "XML Format Configuration<br><i>(XML format specifications, <br>e.g. for TEI)</i>"}
            stam_xmlconfig ==> stam_fromxml

            stam_fromxml["stam fromxml<br><i>converts/untangles XML to STAM</i>"] 
            stam_webanno["stam webanno<br><i>Conversion to W3C Web Annotations</i>"]
            stam_annotations@{ shape: docs, label: "<b>STAM Annotations</b><br><i>(stand-off annotations with references to texts<br>STAM JSON/CSV/CBOR or non-serialised in memory)</i>"}
            teisource ==> stam_fromxml
            pagexmlsource ==> stam_fromxml
            folia2stam ==> stam_annotations
            stam_fromxml ==> stam_annotations
            stam_annotations ==> stam_webanno
        end
    end


    subgraph targets
        direction LR

        folia2stam ==> texts
        stam_fromxml ==> texts
        
        stam_webanno ==> webanno

        texts@{ shape: docs, label: "<b>Texts</b><br><i>Plain texts (UTF-8)</i>"}
        webanno@{ shape: docs, label: "<b>W3C Web Annotations</b><br><i>Stand-off annotations (JSONL + JSON-LD)</i>"}
    end

    subgraph ingest
        direction TB

        texts ==> uploader
        webanno ==> uploader
        uploader["Uploader<br><i>(Simple project-specific uploader script, python)</i>"]
        uploader --> uploader_annorepo_client
        uploader --> uploader_textrepo_client

        uploader_annorepo_client[["annorepo-client (python)"]]
        uploader_textrepo_client[["textrepo-client (python)"]]

        uploader_annorepo_client -- "HTTPS POST/PUT + W3C Web Annotation Protocol" --> annorepo
        uploader_textrepo_client -- "HTTPS POST/PUT + TextRepo API" --> textrepo

        annorepo[/"<b>Annorepo</b><br><i>(web annotation server)</i>"/]
        mongodb[/"MongoDB<br><i>(NoSQL database server)</i>"/]
        annorepo_db[("Annotation Database")]
        annorepo --> mongodb --> annorepo_db


        indexer["<b>Indexer</b><br><i>(project-specific, multiple implementations exist)</i>"]

        indexer -- "HTTP(S) GET" --> annorepo
        indexer -- "HTTP(S) GET" --> textrepo

        textrepo[/"<b>Textrepo</b><br><i>(text server)</i>"/]
        postgresql[/"Postgresql<br><i>(Database System)</i>"/]

        textrepo -- "Postgresql" --> postgresql

        indexer -- "HTTP(S) POST + ElasticSearch API" --> elasticsearch

        subgraph brinta
            elasticsearch[/"ElasticSearch<br><i>(Search engine)</i>"/]
            searchindex[("Text and annotation index<br><i>(for full text text search and faceted annotation search)</i>")]
            elasticsearch --> searchindex
        end

        uploader -. "(manually invoked afterwards)" -.-> indexer

        
    end


    linkStyle default background:transparent,color:#009
```

#### Notes

* TextRepo may be substituted with TextSurf in the future

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
