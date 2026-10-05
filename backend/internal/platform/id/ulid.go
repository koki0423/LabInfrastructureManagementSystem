package id

import (
	"crypto/rand"
	"time"

	ulid "github.com/oklog/ulid/v2"
)

type Clock interface{ Now() time.Time }
type RealClock struct{}

func (RealClock) Now() time.Time { return time.Now().UTC() }

type Generator interface{ New() string }

type ULIDGen struct{ Clock Clock }

func NewULIDGen() ULIDGen { return ULIDGen{Clock: RealClock{}} }

func (g ULIDGen) New() string {
	entropy := ulid.Monotonic(rand.Reader, 0)
	return ulid.MustNew(ulid.Timestamp(g.Clock.Now()), entropy).String()
}
