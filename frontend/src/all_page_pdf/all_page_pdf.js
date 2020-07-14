import React, { useState } from "react";
import { Document, Page, pdfjs} from "react-pdf";
import "./all_page_pdf.css";
import { SizeMe } from 'react-sizeme';

pdfjs.GlobalWorkerOptions.workerSrc = `//cdnjs.cloudflare.com/ajax/libs/pdf.js/${pdfjs.version}/pdf.worker.js`;

export default function AllPages(props) {
  const [numPages, setNumPages] = useState(null);

  function onDocumentLoadSuccess({ numPages }) {
    setNumPages(numPages);
    removeTextLayerOffset();
  }
  
  function removeTextLayerOffset() {
    const textLayers = document.querySelectorAll(".react-pdf__Page__textContent");
      textLayers.forEach(layer => {
        const { style } = layer;
        style.top = "0";
        style.left = "0";
        style.transform = "";
    });
  }

  const { pdf } = props;
  return (
    <SizeMe 
      monitorHeight
      refreshRate={128}
      refreshMode={"debounce"}
      render={({ size }) =>
      <div>
        <Document
          file={pdf}
          options={{ workerSrc: "pdf.worker.js" }}
          onLoadSuccess={onDocumentLoadSuccess}
        >
          {Array.from(new Array(numPages), (el, index) => (
              <Page width = {size.width} key={`page_${index + 1}`} pageNumber={index + 1} />
          ))}
        </Document>
      </div>
    }
    />
  );
}