# Team Text - Software Architecture Overview

## 1. Service Oriented Architecture for Text Collections

### 1.1. Current SOA for Text Collections

This is our current Service Oriented Architecture for making available (enriched) Text Collections, it still includes uses of TextRepo.

```mermaid
%%{init: {"flowchart": {"htmlLabels": true},
    "theme": "default",
    'themeVariables': {
      'edgeLabelBackground': 'transparent'
    }
}}%%
flowchart TD


    user@{ shape: sl-rect, label: "End-user (Researcher)<br>in web browser"}
    user -- "HTTPS (UI)" --> textannoviz
    subgraph frontend
        tavconf@{ shape: doc, label: "TextAnnoViz Configuration<br><i>(project specific)</i>"}
        textannoviz --> tavconf

        textannoviz[/"<b>TextAnnoViz</b><br>(web front-end)"/]
        mirador@{shape: subproc, label: "Mirador<br><i>IIIF Image viewer</i>"}
        textannoviz --> mirador
    end

    techuser@{ shape: sl-rect, label: "Technical user/machine<br>via a web client"}

    techuser -- "HTTPS + Broccoli API" --> broccoli
    subgraph middleware
        textannoviz -- "HTTPS + Broccoli API" --> broccoli
        broccoli[/"<b>Broccoli</b><br><i>(broker)</i>"/]

        broccoli_annorepoclient@{shape: subproc, label: "annorepo-client"}
        broccoli --> broccoli_annorepoclient 

        broccoli --> brocconf
        brocconf@{ shape: doc, label: "Broccoli Configuration<br><i>(project specific)</i>"}
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

    linkStyle default background:transparent,color:#060
```

#### Legend

* Arrows follow caller (or loader) direction, response data flows in opposite direction. Edge labels denote communication protocols.
* Rectangles represent processes.
* Parallelograms represent networked processes (i.e. services).
* Rectangles with an extra marked block left and right represent software libraries
* Third party software is grayed out
* Project-specific configuration files are not depicted for the backends, but are assumed for all service deployments

### 1.2. New proposed SOA for Text Collections 

This is our new proposed Service Oriented Architecture for making available (enriched) Text Collections, it switches out Textrepo for textsurf and adds a query expansion service (kweepeer).

```mermaid
%%{init: {"flowchart": {"htmlLabels": true},
    "theme": "default",
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
        kweepeerfrontend@{shape: subproc, label: "Kweepeer Frontend<br><i>(Query expansion UI)</i>"}
        textannoviz --> mirador
        textannoviz --> kweepeerfrontend

        tavconf@{ shape: doc, label: "TextAnnoViz Configuration<br><i>(project specific)</i>"}
        textannoviz --> tavconf
    end

    techuser@{ shape: sl-rect, label: "Technical user/machine<br>via a web client"}

    techuser -- "HTTPS + Broccoli API" --> broccoli
    subgraph middleware
        textannoviz -- "HTTPS + Broccoli API" --> broccoli
        broccoli[/"<b>Broccoli</b><br><i>(broker)</i>"/]

        broccoli_annorepoclient@{shape: subproc, label: "annorepo-client"}
        broccoli_elasticclient@{shape: subproc, label: "elasticsearch-java<br><i>(client)</i>"}
        broccoli --> broccoli_annorepoclient 
        broccoli --> broccoli_elasticclient 

        broccoli --> brocconf
        brocconf@{ shape: doc, label: "Broccoli Configuration<br><i>(project specific)</i>"}

    end


    subgraph backend
    
        annorepo[/"<b>Annorepo</b><br><i>(web annotation server)</i>"/]
        mongodb[/"MongoDB<br><i>(NoSQL database server)</i>"/]
        annorepo_db[("Annotation Database")]
        annorepo --> mongodb --> annorepo_db

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

    linkStyle default background:transparent,color:#060
```

#### Notes

* Kweepeer is not further expanded in this schema, see [https://github.com/knaw-huc/kweepeer/blob/master/README.md#architecture](this schema) for further expansion.


## 2. Data Conversion Pipelines

### 2.1. Current conversion pipeline for Text Collections

```mermaid
%%{init: {"flowchart": {"htmlLabels": true}} }%%
flowchart TD

    subgraph sources["Sources (pick one)"]
        direction LR
        teisource@{ shape: docs, label: "Enriched texts<br>(TEI XML)"}
        pagexmlsource@{ shape: docs, label: "Enriched texts<br>(Page XML)"}
    end

    subgraph conversion
        direction TB

        subgraph with_textfabric_factory["With Text Fabric Factory (Python API)"]
            direction TB
            teisource ==> tff_fromtei
            pagexmlsource ==> tff_fromxml
            tff_fromtei["tff.convert.tei"]
            tff_fromxml["tff.convert.xml"]
            tfdata@{ shape: docs, label: "Text Fabric Data"}
            tff_watm["tff.convert.watm"]
            watm@{ shape: docs, label: "WATM (Web Annotation Text Model)<br><i>(internal intermediary representation)</i>"}
            tff_fromtei ==> tfdata 
            tff_fromxml ==> tfdata
            tfdata ==> tff_watm ==> watm
        end 

        subgraph with_untangle["With un-t-ann-gle"]
            direction TB
            watm ==> untangle
            untangle["<b>un-t-ann-gle</b><br><i>Project-specific conversion pipelines to create texts and web annotations from joined data. Generic uploader for annorepo/textrepo.</i>"]
            untangle_annorepo_client@{shape: subproc, label: "annorepo-client"}
            untangle_textrepo_client@{shape: subproc, label: "textrepo-client"}

            webanno@{ shape: docs, label: "<b>W3C Web Annotations</b><br><i>Stand-off annotations (JSONL)</i>"}
            textsegments@{ shape: docs, label: "<b>Text Segments</b><br><i>JSON for Textrepo</i>"}

            untangle ==> textsegments ==> untangle_textrepo_client
            untangle ==> webanno ==> untangle_annorepo_client
        end
    end

    subgraph ingest
        direction TB
        untangle_annorepo_client -- "HTTPS POST/PUT + W3C Web Annotation Protocol" --> annorepo
        untangle_textrepo_client -- "HTTPS POST/PUT + TextRepo API" --> textrepo

        techuser@{ shape: sl-rect, label: "Technical user/machine<br>via a web client"}
        techuser --> indexer

        annorepo[/"<b>Annorepo</b><br><i>(web annotation server)</i>"/]
        mongodb[/"MongoDB<br><i>(NoSQL database server)</i>"/]
        annorepo_db[("Annotation Database")]
        annorepo --> mongodb --> annorepo_db


        indexer[/"<b>Indexer</b><br><i>(project-specific, multiple implementations exist)</i>"/]

        indexer -- "HTTP(S) GET" --> annorepo
        indexer -- "HTTP(S) GET" --> textrepo

        textrepo[/"<b>Textrepo</b><br><i>(text server)</i>"/]
        postgresql[/"Postgresql<br><i>(Database System)</i>"/]

        textrepo -- "Postgresql" --> postgresql

        subgraph brinta
            elasticsearch[/"ElasticSearch<br><i>(Search engine)</i>"/]
            searchindex[("Text and annotation index<br><i>(for full text text search and faceted annotation search)</i>")]
            elasticsearch --> searchindex
            indexer -- "HTTP(S) POST + ElasticSearch API" --> elasticsearch
        end

        
    end

    sources ~~~ conversion ~~~ ingest


    classDef thirdparty fill:#ccc,color:#111
    class mongodb,elasticsearch,postgresql thirdparty

    classDef abstract color:#f00
    class indexer abstract

    linkStyle default background:transparent,color:#060
```

#### Legend

* Thick lines represent data flow rather than caller direction
* Node with red text denote abstractions rather than specific software 

### 2.2. Conversion with STAM

As used in the Brieven van Hooft project (FoLiA source).

```mermaid
%%{init: {"flowchart": {"htmlLabels": true}} }%%
flowchart TD

    subgraph sources["Sources (pick one)"]
        direction LR
        teisource@{ shape: docs, label: "Enriched texts<br>(TEI XML)"}
        foliasource@{ shape: docs, label: "Enriched texts<br>(FoLiA XML)"}
        pagexmlsource@{ shape: docs, label: "Enriched texts<br>(Page XML)"}
    end

    subgraph conversion
        direction LR
        subgraph with_folia_tools["with FoLiA-tools (CLI)"]
            direction TB
            foliasource ==> folia2stam
            folia2stam["folia2stam<br><i>untangles FoLiA XML to STAM</i>"]
        end

        subgraph with_stam_tools["with stam-tools (CLI)"]
            direction TB
            stam_xmlconfig@{ shape: docs, label: "XML Format Configuration<br><i>(XML format specifications, <br>e.g. for TEI)</i>"}
            stam_xmlconfig ==> stam_fromxml

            stam_fromxml["stam fromxml<br><i>untangles XML to STAM</i>"] 
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

    linkStyle default background:transparent,color:#060
```

#### Notes

Ingest is omitted from this schema but follows largely the same as in 2.1. A minimal uploader to annorepo and textrepo/textsurf is used instead of un-t-ann-gle. This can also be omitted entirely if stamd is used directly.
