import{n as e,r as t,t as n}from"./index-DAhXxFGD.js";import{t as r}from"./CopyButton-Crg9GoJG.js";var i=t(),a=e();function o(e,t){return`MIT License

Copyright (c) ${e} ${t}

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.`}function s(e,t){return`Apache License 2.0

Copyright ${e} ${t}

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.`}function c(){let[e,t]=(0,i.useState)(`mit`),[c,l]=(0,i.useState)(`UtilityKit Contributors`),u=new Date().getFullYear(),d=(0,i.useMemo)(()=>e===`mit`?o(u,c):s(u,c),[e,c,u]);return(0,a.jsxs)(n,{title:`license — License Helper`,subtitle:`_license_helper.sh`,badge:{label:`Live`,kind:`live`},footer:`Generated with the current year, matching the CLI's --generate output exactly.`,children:[(0,a.jsxs)(`div`,{className:`uk-row`,children:[(0,a.jsxs)(`div`,{className:`uk-field`,children:[(0,a.jsx)(`label`,{children:`Type`}),(0,a.jsxs)(`select`,{className:`uk-select`,value:e,onChange:e=>t(e.target.value),children:[(0,a.jsx)(`option`,{value:`mit`,children:`mit`}),(0,a.jsx)(`option`,{value:`apache`,children:`apache`})]})]}),(0,a.jsxs)(`div`,{className:`uk-field`,style:{flex:2},children:[(0,a.jsx)(`label`,{children:`Name`}),(0,a.jsx)(`input`,{className:`uk-input`,value:c,onChange:e=>l(e.target.value)})]})]}),(0,a.jsxs)(`div`,{className:`uk-out-box`,children:[(0,a.jsx)(r,{text:d}),(0,a.jsx)(`pre`,{className:`uk-line`,style:{margin:0,fontSize:12,paddingRight:60},children:d})]})]})}export{c as default};