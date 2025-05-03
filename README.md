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
        textannoviz -- "HTTP + Broccoli API" --> broccoli
        broccoli[/"<b>Broccoli</b><br><i>(broker)</i>"/]

        broccoli_annorepoclient@{shape: subproc, label: "annorepo-client"}
        broccoli --> broccoli_annorepoclient 
    end


    subgraph backend
    
        annorepo[/"<b>Annorepo</b><br><i>(web annotation server)</i>"/]
        mongodb[/"MongoDB<br><i>(NoSQL database server)</i>"/]
        annorepo_db[("Annotation Database")]
        annorepo --> mongodb --> annorepo_db

        textindex[("Text index")]
        texts@{ shape: database, label: "Text database"}
        textscans@{ shape: docs, label: "Text Scans<br><i>(image files)</i>"}
        textmetadb@{ shape: database, label: "Text metadata database"}

        textrepo[/"<b>Textrepo</b><br><i>(text server)</i>"/]
        postgresql[/"Postgresql<br><i>(Database System)</i>"/]
        elasticsearch[/"ElasticSearch<br><i>(Search engine)</i>"/]

        textrepo --> postgresql
        textrepo --> elasticsearch

        elasticsearch --> texts
        postgresql --> textmetadb



        cantaloupe[/"<b>Cantaloupe</b><br><i>(IIIF Image server)</i>"/]
        manifests@{ shape: docs, label: "IIIF Manifests"}
        cantaloupe --> textscans
        cantaloupe --> manifests


        sdswitch[/"SD-Switch<br><i>(broker for various<br>structured data services)</i>"/]

        broccoli_annorepoclient -- "HTTP + W3C Web Annotation Protocol" --> annorepo
        broccoli -- "HTTP + IIIF Image API" --> cantaloupe
        broccoli -- "HTTP" --> sdswitch
        broccoli -- "HTTP + TextRepo API" --> textrepo

        elasticsearch --> textindex


        mirador -- "HTTPS + IIIF Image API" --> cantaloupe
    end


    classDef thirdparty fill:#ccc,color:#111
    class cantaloupe,mongodb,elasticsearch,postgresql,mirador thirdparty
```

**Notes**:

* SD-Switch is not further expanded here because I have no idea what it actually serves

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
        textannoviz -- "HTTP + Broccoli API" --> broccoli
        broccoli[/"<b>Broccoli</b><br><i>(broker)</i>"/]

        broccoli_annorepoclient@{shape: subproc, label: "annorepo-client"}
        broccoli --> broccoli_annorepoclient 

        kweepeerfrontend --> broccoli
    end


    subgraph backend
    
        annorepo[/"<b>Annorepo</b><br><i>(web annotation server)</i>"/]
        mongodb[/"MongoDB<br><i>(NoSQL database server)</i>"/]
        annorepo_db[("Annotation Database")]
        annorepo --> mongodb --> annorepo_db

        elasticsearch[/"ElasticSearch<br><i>(Search engine)</i>"/]
        textindex[("Text index")]
        texts@{ shape: docs, label: "Text files<br><i>(plain text, UTF-8)</i>"}
        textscans@{ shape: docs, label: "Text Scans<br><i>(image files)</i>"}

        textsurf[/"<b>Textsurf</b><br>(text server)"/]
        textframe@{shape: subproc, label: "Textframe<br><i>(text referencing library)</i>"}


        cantaloupe[/"<b>Cantaloupe</b><br><i>(IIIF Image server)</i>"/]
        manifests@{ shape: docs, label: "IIIF Manifests"}
        cantaloupe --> textscans
        cantaloupe --> manifests

        kweepeer[/"<b>Kweepeer</b><br><i>Query Expansion server</i>"/]

        sdswitch[/"SD-Switch<br><i>(broker for various<br>structured data services)</i>"/]

        broccoli_annorepoclient -- "HTTP + W3C Web Annotation Protocol" --> annorepo
        broccoli -- "HTTP + IIIF Image API" --> cantaloupe
        broccoli -- "HTTP" --> sdswitch
        broccoli -- "HTTP + Textsurf API" --> textsurf
        broccoli -- "HTTP + Kweepeer API" --> kweepeer

        broccoli --> elasticsearch --> textindex

        textsurf --> textframe -->  texts
        textsurf --> texts

        mirador -- "HTTPS + IIIF Image API" --> cantaloupe
    end


    classDef thirdparty fill:#ccc,color:#111
    class cantaloupe,mongodb,elasticsearch,postgresql,mirador thirdparty
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

