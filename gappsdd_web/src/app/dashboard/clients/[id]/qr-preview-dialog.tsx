"use client";

import { useRef, useCallback } from "react";
import { QRCode } from "react-qrcode-logo";
import { Download } from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";

export function QrPreviewDialog({
  open,
  onOpenChange,
  gardenId,
  gardenName,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  gardenId: string;
  gardenName: string;
}) {
  const qrRef = useRef<QRCode>(null);

  const handleDownload = useCallback(() => {
    qrRef.current?.download("png", `qr-${gardenName.toLowerCase().replace(/\s+/g, "-")}`);
  }, [gardenName]);

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-sm">
        <DialogHeader>
          <DialogTitle>QR del Jardín</DialogTitle>
          <DialogDescription>{gardenName}</DialogDescription>
        </DialogHeader>

        <div className="flex justify-center py-4">
          <QRCode
            ref={qrRef}
            value={gardenId}
            size={280}
            logoImage="/logo.svg"
            logoWidth={60}
            logoHeight={60}
            logoPadding={4}
            logoPaddingStyle="circle"
            qrStyle="dots"
            eyeRadius={8}
            ecLevel="H"
            bgColor="#FFFFFF"
            fgColor="#17340E"
          />
        </div>

        <DialogFooter>
          <Button onClick={handleDownload}>
            <Download className="mr-2 h-4 w-4" />
            Descargar PNG
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
