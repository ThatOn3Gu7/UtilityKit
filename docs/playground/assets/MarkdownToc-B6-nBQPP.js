import{n as e,r as t,t as n}from"./index-DAhXxFGD.js";import{t as r}from"./CopyButton-Crg9GoJG.js";var i=t(),a=e();function o(e){return e.toLowerCase().replace(/[^a-z0-9 _-]/g,``).replace(/\s+/g,`-`).replace(/-+/g,`-`).replace(/^-|-$/g,``)}function s(e){let t=e.split(`
`),n=[],r=!1;for(let e of t){if(e.trim().startsWith("```")){r=!r;continue}if(r)continue;let t=e.match(/^(#{1,6})\s+(.+)/);t&&n.push({level:t[1].length,title:t[2].trim(),anchor:o(t[2].trim())})}return n}function c(){let[e,t]=(0,i.useState)(`# UtilityKit

## Features

Text here.

## Usage

### Quick Start

More text.

## Contributing
`),o=(0,i.useMemo)(()=>s(e),[e]),c=o.map(e=>`${`  `.repeat(e.level-1)}- [${e.title}](#${e.anchor})`).join(`
`);return(0,a.jsxs)(n,{title:`toc — Markdown TOC`,subtitle:`_markdown_toc.sh`,badge:{label:`Live`,kind:`live`},footer:`Same anchor-slug rules as GitHub Markdown, computed client-side.`,children:[(0,a.jsxs)(`div`,{className:`uk-field`,children:[(0,a.jsx)(`label`,{children:`Markdown input`}),(0,a.jsx)(`textarea`,{className:`uk-textarea`,style:{minHeight:150,fontSize:12.5},value:e,onChange:e=>t(e.target.value)})]}),(0,a.jsx)(`div`,{className:`uk-out-box`,children:o.length===0?(0,a.jsx)(`div`,{className:`uk-dim`,children:`No headings found; TOC would be empty.`}):(0,a.jsxs)(a.Fragment,{children:[(0,a.jsx)(r,{text:c}),(0,a.jsxs)(`div`,{className:`uk-dim`,style:{fontSize:11,marginBottom:6},children:[`Generated TOC (`,o.length,` entries)`]}),(0,a.jsx)(`pre`,{className:`uk-line uk-cyan`,style:{margin:0,fontSize:12.5,paddingRight:60},children:c})]})})]})}export{c as default};