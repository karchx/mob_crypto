package main

import (
	"context"
	"encoding/csv"
	"fmt"
	"log"
	"os"

	"github.com/karchx/gsexpenses/internal"
	"google.golang.org/api/option"
	"google.golang.org/api/sheets/v4"
)

func main() {
	ctx := context.Background()

	// scopes
	config := internal.GetClient()
	writer, file, err := createCsv("expenses_ksandoval.csv")
	if err != nil {
		log.Fatalf("[main] failed create csv: %v", err)
	}
	defer file.Close()
	defer writer.Flush()
	writer.Write([]string{"cycle", "date", "amount", "description", "category", "type"})

	srv, err := sheets.NewService(ctx, option.WithHTTPClient(config.Client(ctx)))
	if err != nil {
		log.Fatalf("Unable to retrieve Sheets client: %v", err)
	}

	spreadsheetId := "1aBNk4Wv9qzvqSN5y7u2xZAK7PkYCxCSdr45fSdRn3AU"
	spreadsheet, err := srv.Spreadsheets.Get(spreadsheetId).Do()
	if err != nil {
		fmt.Printf("[gsexpenses]: error get spreadsheet %+v", err)
	}

	for _, sheet := range spreadsheet.Sheets {
		sheetName := sheet.Properties.Title
		if sheetName == "Resumen" {
			continue
		}

		rangeExpenses := fmt.Sprintf("'%s'!B5:E", sheetName)
		rangeProfit := fmt.Sprintf("'%s'!G5:j", sheetName)

		resp, err := srv.Spreadsheets.Values.BatchGet(spreadsheetId).Ranges(rangeExpenses, rangeProfit).Do()
		if err != nil {
			log.Printf("[gsexpenses] Read range sheet %s: %v", sheetName, err)
			continue
		}

		if len(resp.ValueRanges) > 0 && resp.ValueRanges[0].Values != nil {
			for _, row := range resp.ValueRanges[0].Values {
				if len(row) > 0 && row[0] != "" {
					record := formatRow(sheetName, row, "expense")
					writer.Write(record)
				}
			}
		}

		if len(resp.ValueRanges) > 1 && resp.ValueRanges[1].Values != nil {
			for _, row := range resp.ValueRanges[1].Values {
				if len(row) > 0 && row[0] != "" {
					record := formatRow(sheetName, row, "income")
					writer.Write(record)
				}
			}
		}

		fmt.Printf("Success extract sheet: %s\n", sheetName)
	}
}

func formatRow(sheetName string, row []any, typeAction string) []string {
	if sheetName == "Transacciones" {
		sheetName = "MOST-RECENT"
	}
	cols := make([]string, 4)
	for i := 0; i < len(row) && i < 4; i++ {
		cols[i] = fmt.Sprintf("%v", row[i])
	}

	return []string{
		sheetName,
		cols[0],    // Date
		cols[1],    // Amount
		cols[2],    // Description
		cols[3],    // Category
		typeAction, // Income or Expense
	}
}

func createCsv(fileName string) (*csv.Writer, *os.File, error) {
	file, err := os.Create(fileName)
	if err != nil {
		return nil, nil, err
	}
	writer := csv.NewWriter(file)
	return writer, file, nil
}
