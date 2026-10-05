package disposals

import (
	"database/sql"
	"time"
)

// DBテーブルと1:1のモデル
type Disposal struct {
	DisposalID       uint64
	DisposalULID     string
	ManagementNumber string
	Quantity         uint
	Reason           sql.NullString
	ProcessedByID    sql.NullString
	DisposedAt       time.Time
}
