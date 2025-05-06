# Team Text - Software Architecture Overview

## 1. Service Oriented Architecture for Text Collections

### 1.1. Current SOA for Text Collections

This is our current Service Oriented Architecture for making available (enriched) Text Collections, it still includes uses of TextRepo.

```{.mermaid format=svg}
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

        broccoli_annorepoclient@{shape: subproc, label: "annorepo-client"}
        broccoli --> broccoli_annorepoclient 
    end


    subgraph backend
    
        annorepo[/"<b>Annorepo</b><br><i>(web annotation server)</i>"/]
        mongodb[/"MongoDB<br><i>(NoSQL database server)</i>"/]
        annorepo_db[("Annotation Database")]
        annorepo -- "HTTP(S) + MongoDB Query API" --> mongodb --> annorepo_db

        textindex[("Text index<br><i>(for full text text search)</i>")]
        annotationindex[("Annotation index<br><i>(for faceted search on annotations)</i>")]

        textscans@{ shape: docs, label: "Text Scans<br><i>(image files)</i>"}
        textdb@{ shape: database, label: "Texts (with metadata) database"}

        textrepo[/"<b>Textrepo</b><br><i>(text server)</i>"/]
        postgresql[/"Postgresql<br><i>(Database System)</i>"/]
        elasticsearch[/"ElasticSearch<br><i>(Search engine)</i>"/]

        textrepo -- "Postgresql" --> postgresql
        broccoli -- "HTTP(S) + ElasticSearch API" --> elasticsearch

        postgresql --> textdb

        cantaloupe[/"<b>Cantaloupe</b><br><i>(IIIF Image server)</i>"/]
        manifests@{ shape: docs, label: "IIIF Manifests"}
        cantaloupe --> textscans

        broccoli_annorepoclient -- "HTTP(S) + W3C Web Annotation Protocol" --> annorepo
        broccoli -- "HTTP(S) + TextRepo API" --> textrepo

        manifest_server[/"nginx<br><i>(static manifest server)</i>"/]
        manifest_server --> manifests


        elasticsearch --> textindex
        elasticsearch --> annotationindex


        mirador -- "HTTPS + IIIF Image API" --> cantaloupe
        mirador -- "HTTPS" --> manifest_server
    end


    classDef thirdparty fill:#ccc,color:#111
    class cantaloupe,mongodb,elasticsearch,postgresql,mirador,manifest_server thirdparty
```

### Legend:

* Arrows follow caller direction, response data flows in opposite direction. Edge labels denote communication protocols.
* Rectangles represent processes.
* Parallelograms represent networked processes (i.e. services).
* Rectangles with an extra marked block left and right represent software libraries
* Third party software is grayed out

### 1.2. New proposed SOA for Text Collections 

This is our new proposed Service Oriented Architecture for making available (enriched) Text Collections, it switches out Textrepo for textsurf and adds a query expansion service (kweepeer).

```{.mermaid format=svg}
flowchart TD


    user@{ shape: sl-rect, label: "End-user (Researcher)<br>in web browser"}
    user -- "HTTPS (UI)" --> textannoviz
    subgraph frontend
        textannoviz[/"<b>TextAnnoViz</b><br>(web front-end)"/]
        mirador@{shape: subproc, label: "Mirador<br><i>IIIF Image viewer</i>"}
        kweepeerfrontend@{shape: subproc, label: "Kweepeer Frontend<br><i>(Query expansion UI)</i>"}
        textannoviz --> mirador
        textannoviz --> kweepeerfrontend
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

    end


    subgraph backend
    
        annorepo[/"<b>Annorepo</b><br><i>(web annotation server)</i>"/]
        mongodb[/"MongoDB<br><i>(NoSQL database server)</i>"/]
        annorepo_db[("Annotation Database")]
        annorepo --> mongodb --> annorepo_db

        elasticsearch[/"ElasticSearch<br><i>(Search engine)</i>"/]
        textindex[("Text index<br><i>(for full text text search)</i>")]
        annotationindex[("Annotation index<br><i>(for faceted search on annotations)</i>")]

        texts@{ shape: docs, label: "Text files<br><i>(plain text, UTF-8)</i>"}
        textscans@{ shape: docs, label: "Text Scans<br><i>(image files)</i>"}

        textsurf[/"<b>Textsurf</b><br>(text server)"/]
        textframe@{shape: subproc, label: "Textframe<br><i>(text referencing library)</i>"}


        cantaloupe[/"<b>Cantaloupe</b><br><i>(IIIF Image server)</i>"/]
        manifests@{ shape: docs, label: "IIIF Manifests"}
        cantaloupe --> textscans

        kweepeer[/"<b>Kweepeer</b><br><i>Query Expansion server</i>"/]

        broccoli_annorepoclient -- "HTTP(S) + W3C Web Annotation Protocol" --> annorepo
        broccoli_elasticclient -- "HTTP(S) + ElasticSearch API" --> elasticsearch
        broccoli -- "HTTP(S) + Textsurf API" --> textsurf

        mirador -- "HTTPS" --> manifest_server
        mirador -- "HTTPS + IIIF Image API" --> cantaloupe

        kweepeerfrontend -- "HTTP(S) + Kweepeer API" --> kweepeer

        manifest_server[/"nginx<br><i>(static manifest server)</i>"/]
        manifest_server --> manifests

        elasticsearch --> textindex
        elasticsearch --> annotationindex

        textsurf --> textframe -->  texts
        textsurf --> texts
    end


    classDef thirdparty fill:#ccc,color:#111
    class cantaloupe,mongodb,elasticsearch,postgresql,mirador,manifest_server,broccoli_elasticclient thirdparty
```

**Notes:**

* Kweepeer is not further expanded in this schema, see [https://github.com/knaw-huc/kweepeer/blob/master/README.md#architecture](this schema) for further expansion.


## 2. Data Conversion Pipelines

```{.mermaid format=svg}
flowchart TD

    subgraph sources["Sources (pick one)"]
        direction LR
        teisource@{ shape: docs, label: "Enriched texts<br>(TEI XML)"}
        foliasource@{ shape: docs, label: "Enriched texts<br>(FoLiA XML)"}
        pagexmlsource@{ shape: docs, label: "Enriched texts<br>(Page XML)"}
    end

    subgraph preprocessing["Conversion"]
        direction LR

        subgraph with_textfabric_factory["With Text Fabric Factory<br>(Python API)"]
            direction TB
            teisource --> tff_fromtei
            pagexmlsource --> tff_fromxml
            tff_fromtei["tff.convert.tei"]
            tff_fromxml["tff.convert.xml"]
            tfdata@{ shape: docs, label: "Text Fabric Data"}
            tff_watm["tff.convert.watm"]
            watm@{ shape: docs, label: "WATM (Web Annotation Text Model)<br><i>(internal intermediary representation)</i>"}
            tff_fromtei --> tfdata 
            tff_fromxml --> tfdata
            tfdata --> tff_watm --> watm
        end 

        subgraph with_untangle["With un-t-ann-gle"]
            direction TB
            watm --> untangle
            untangle["<b>un-t-ann-gle</b><br><i>Project-specific conversion pipelines to creates texts and web annotations from joined data. Generic uploader for annorepo/textrepo.</i>"]
        end

        subgraph with_folia_tools["with FoLiA-tools (CLI)"]
            direction TB
            foliasource --> folia2stam
        end

        subgraph with_stam_tools["with stam-tools (CLI)"]
            direction TB
            stam_xmlconfig@{ shape: docs, label: "XML Format Configuration<br><i>(XML format specifications, <br>e.g. for TEI)</i>"}
            stam_xmlconfig --> stam_fromxml

            stam_fromxml["stam fromxml"] 
            stam_webanno["stam webanno"]
            stam_annotations@{ shape: docs, label: "<b>STAM Annotations</b><br><i>(stand-off annotations with references to texts, STAM JSON)</i>"}
            teisource --> stam_fromxml
            pagexmlsource --> stam_fromxml
            folia2stam --> stam_annotations
            stam_fromxml --> stam_annotations
            stam_annotations --> stam_webanno
        end

    end


    subgraph targets
        direction LR

        untangle --> textsegments
        folia2stam --> texts
        stam_fromxml --> texts
        
        untangle --> webanno
        stam_webanno --> webanno

        texts@{ shape: docs, label: "<b>Texts</b><br><i>Plain texts (UTF-8)</i>"}
        webanno@{ shape: docs, label: "<b>W3C Web Annotations</b><br><i>Stand-off annotations (JSONL)</i>"}

        textsegments@{ shape: docs, label: "<b>Text Segments</b><br><i>JSON for Textrepo</i>"}
    end

    sources ~~~ preprocessing
    preprocessing ~~~ targets
```

