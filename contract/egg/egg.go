package main

import (
	"encoding/json"
	"fmt"
	"log"
	"time"

	"github.com/golang/protobuf/ptypes"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SmartContract struct{
	contractapi.Contract
}

// Egg구조체 정의
type Egg struct {
	ParentChickenID string	`json:"cid"`
	EggID			string	`json:"eid"`
	SpawnDate		string	`json:"spawndate"`
	Count			int		`json:"count"`
	ShipmentInfo	string	`json:"shipinfo"`
	Owner			string	`json:"owner"`
	Status 			string	`json:"status"`
	//registered, shiprequested, shipped
}

type HistoryQueryResult struct {
	Record    	*Egg    `json:"record"`
	TxId     	string    `json:"txId"`
	Timestamp 	time.Time `json:"timestamp"`
	IsDelete  	bool      `json:"isDelete"`
}

// RegisterEgg
func (s *SmartContract) RegisterEgg(ctx contractapi.TransactionContextInterface, cid string, eid string, spawndate string, count int, owner string) error {

	// 중복확인
	eggJSON, err := ctx.GetStub().GetState(eid)
	if err != nil {
		return err
	}
	if eggJSON != nil {
		return fmt.Errorf("Duplicated ID:", eid)
	}

	// 구조체생성
	egg := Egg{
		ParentChickenID: cid,
		EggID: eid,
		SpawnDate: spawndate,
		Count: count,
		Owner: owner,
		Status: "registered",
	}

	// 마샬-직렬화 JSON

	eggJSON, err = json.Marshal(egg)
	if err != nil {
		return err
	}

	// PutState
	return ctx.GetStub().PutState(eid, eggJSON)

}
// QueryEgg
func (s *SmartContract) QueryEgg(ctx contractapi.TransactionContextInterface, eid string) (*Egg, error) {
	eggJSON, err := ctx.GetStub().GetState(eid)
	if err != nil {
		return nil, err
	}
	// EGG유무 검증
	if eggJSON == nil {
		return nil, fmt.Errorf("The egg %s does not exist", eid)
	}

	// 빈구조체에 객체화
	var egg Egg
	err = json.Unmarshal(eggJSON, &egg)
	if err != nil {
		return nil, err
	}

	return &egg, nil
}
// RequestShip
func (s *SmartContract) RequestShip(ctx contractapi.TransactionContextInterface, eid string, shipinfo string) error {
	egg, err := s.QueryEgg(ctx, eid)
	if err != nil {
		return err
	}

	// 상태검증
	if egg.Status != "registered" {
		return fmt.Errorf("Not valid egg status. current state: %s", egg.Status)
	}

	egg.ShipmentInfo = shipinfo
	egg.Status = "shiprequested"
	
	eggJSON, err := json.Marshal(egg)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(eid, eggJSON)
}
// ShipEgg
func (s *SmartContract) ShipEgg(ctx contractapi.TransactionContextInterface, eid string) error {
	egg, err := s.QueryEgg(ctx, eid)
	if err != nil {
		return err
	}

	// 상태검증
	if egg.Status != "shiprequested" {
		return fmt.Errorf("Not valid egg status. current state: %s", egg.Status)
	}

	egg.Status = "shipped"

	eggJSON, err := json.Marshal(egg)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(eid, eggJSON)
}
// QueryEggHistory
func (s *SmartContract) QueryEggHistory (ctx contractapi.TransactionContextInterface, eid string) ([]HistoryQueryResult, error) {
	log.Printf("QueryEggHistory: ID %v", eid)

	resultsIterator, err := ctx.GetStub().GetHistoryForKey(eid)
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	var records []HistoryQueryResult

	for resultsIterator.HasNext() {
		response, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var egg Egg
		if len(response.Value) > 0 {
			err = json.Unmarshal(response.Value, &egg)
			if err != nil {
				return nil, err
			}
		} else {
			egg = Egg{
				EggID: eid,
			}
		}

		timestamp, err := ptypes.Timestamp(response.Timestamp)
		if err != nil {
			return nil, err
		}

		record := HistoryQueryResult{
			TxId: 		response.TxId,
			Timestamp:	timestamp,
			Record:		&egg,
			IsDelete:	response.IsDelete,
		}
		records = append(records, record)
	}
	return records, nil
}

// main
func main() {
	chaincode ,err := contractapi.NewChaincode(&SmartContract{})
	if err != nil {
		log.Panicf("Error creating egg chaincode: %v", err)
	}

	if err := chaincode.Start(); err != nil {
		log.Panicf("Error starting egg chaincode: %v", err)
	}
}